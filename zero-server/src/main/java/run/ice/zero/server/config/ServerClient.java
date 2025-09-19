package run.ice.zero.server.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.support.RestClientAdapter;
import org.springframework.web.service.invoker.HttpServiceProxyFactory;
import run.ice.zero.server.api.DemoApi;

/**
 * @author DaoDao
 */
@Configuration
public class ServerClient {

    private final HttpServiceProxyFactory httpServiceProxyFactory;

    @Autowired
    public ServerClient(@Value("${app.service.zero.server:server.zero}") String service, RestClient.Builder restClientBuilder) {
        String url = (service.matches("^https?://.*") ? service : "http://" + service) + "/";
        this.httpServiceProxyFactory = HttpServiceProxyFactory.builderFor(RestClientAdapter.create(restClientBuilder.baseUrl(url).build())).build();
    }

    @Bean
    public DemoApi demoApi() {
        return httpServiceProxyFactory.createClient(DemoApi.class);
    }

}
