package run.ice.zero.server.config;

import io.micrometer.core.instrument.MeterRegistry;
import lombok.NonNull;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.micrometer.metrics.autoconfigure.MeterRegistryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import run.ice.zero.server.constant.AppConstant;

import java.net.InetAddress;
import java.net.UnknownHostException;

/**
 * @author DaoDao
 */
@Configuration
public class MetricsConfig {

    @Value("${spring.application.name:}")
    private String application;

    @Bean
    public MeterRegistryCustomizer<@NonNull MeterRegistry> metricsCommonTags() {
        String hostname = hostname();
        return (registry) -> registry.config()
                .commonTags("service.name", application)
                .commonTags("service.namespace", AppConstant.NAMESPACE)
                .commonTags("application", application)
                .commonTags("namespace", AppConstant.NAMESPACE)
                .commonTags("hostname", hostname)
                .commonTags("instance", hostname)
                ;
    }

    private static String hostname() {
        String hostname = System.getenv("HOSTNAME");
        if (hostname == null) {
            try {
                hostname = InetAddress.getLocalHost().getHostName();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
            if (null == hostname || hostname.isEmpty()) {
                try {
                    hostname = InetAddress.getLocalHost().getHostAddress();
                } catch (UnknownHostException e) {
                    throw new RuntimeException(e);
                }
            }
        }
        return hostname;
    }

}
