package run.ice.zero.server.interceptor;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.util.PathMatcher;
import run.ice.zero.server.config.LoggerConfig;

import java.io.IOException;
import java.net.URI;
import java.util.List;

@Slf4j
@Component
public class RestLoggerInterceptor implements ClientHttpRequestInterceptor {

    @Resource
    private LoggerConfig loggerConfig;

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body, ClientHttpRequestExecution execution) throws IOException {

        URI uri = request.getURI();
        HttpMethod method = request.getMethod();
        int defaultLimit = 1024 * 10;
        boolean doLog = Boolean.TRUE;

        List<String> excludeUrls = loggerConfig.getExcludeUrls();
        if (excludeUrls != null && !excludeUrls.isEmpty()) {
            for (String excludeUrl : excludeUrls) {
                PathMatcher pathMatcher = new AntPathMatcher();
                if (pathMatcher.match(excludeUrl, uri.toString())) {
                    doLog = Boolean.FALSE;
                    break;
                }
            }
        }

        if (doLog && HttpMethod.POST.equals(method)) {
            log.info("C > : {} {}", method, uri);

            HttpHeaders requestHeaders = request.getHeaders();
            log.info("C > : {}", requestHeaders);

            int limit = defaultLimit;
            if (MediaType.MULTIPART_FORM_DATA.isCompatibleWith(requestHeaders.getContentType())) {
                limit = 1024;
            }

            String requestBody = body.length > limit ? (new String(body, 0, limit) + " ...") : new String(body);
            log.info("C > : {}", requestBody);
        }

        ClientHttpResponse response = execution.execute(request, body);

        if (doLog && HttpMethod.POST.equals(method)) {
            HttpStatusCode statusCode = response.getStatusCode();
            if (statusCode.isError()) {
                String statusText = response.getStatusText();
                log.error("C < : {} {}", statusCode.value(), statusText);
            }

            HttpHeaders responseHeaders = response.getHeaders();
            log.info("C < : {}", responseHeaders);

            int limit = defaultLimit;
            if (responseHeaders.containsHeader(HttpHeaders.CONTENT_DISPOSITION)) {
                limit = 256;
            }

            byte[] bytes = response.getBody().readAllBytes();
            String responseBody = bytes.length > limit ? (new String(bytes, 0, limit) + " ...") : new String(bytes);
            log.info("C < : {}", responseBody);
            return new CustomizerClientHttpResponse(response, bytes);
        }

        return response;
    }

}
