package run.ice.zero.server.config;

import jakarta.annotation.Resource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.BufferingClientHttpRequestFactory;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestTemplate;
import run.ice.zero.server.interceptor.RestLoggerInterceptor;

/**
 * @author DaoDao
 */
@Configuration
public class RestConfig {

    @Resource
    private RestLoggerInterceptor restLoggerInterceptor;

    @Bean
    public RestClient.Builder builder(RestTemplate restTemplate) {
        // builder.interceptors(restLoggerInterceptor);
        BufferingClientHttpRequestFactory requestFactory = new BufferingClientHttpRequestFactory(restTemplate.getRequestFactory());
        RestClient.Builder builder = RestClient.builder(restTemplate);
        builder.requestInterceptors(interceptors -> {
            if (!interceptors.contains(restLoggerInterceptor)) {
                interceptors.add(restLoggerInterceptor);
            }
        });
        builder.requestFactory(requestFactory);
        return builder;
    }

    @Bean
    public RestClient restClient(RestClient.Builder builder) {
        // builder.requestInterceptor(restLoggerInterceptor);
        builder.requestInterceptors(interceptors -> {
            if (!interceptors.contains(restLoggerInterceptor)) {
                interceptors.add(restLoggerInterceptor);
            }
        });
        return builder.build();
    }

    @Bean
    public RestTemplate restTemplate() {
        // builder.interceptors(restLoggerInterceptor);
        RestTemplate restTemplate = new RestTemplate();
        if (!restTemplate.getInterceptors().contains(restLoggerInterceptor)) {
            restTemplate.getInterceptors().add(restLoggerInterceptor);
        }
        BufferingClientHttpRequestFactory requestFactory = new BufferingClientHttpRequestFactory(restTemplate.getRequestFactory());
        restTemplate.setRequestFactory(requestFactory);
        return restTemplate;
    }

}
