package run.ice.zero.server.helper;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Map;

@Slf4j
@Component
public class HttpHelper {

    private HttpServletRequest getHttpServletRequest() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        assert attributes != null;
        return attributes.getRequest();
    }

    public String getHeader(String name) {
        return getHttpServletRequest().getHeader(name);
    }

    public Map<String, String[]> getParameterMap() {
        return getHttpServletRequest().getParameterMap();
    }

}
