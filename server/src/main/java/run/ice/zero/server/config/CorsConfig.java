package run.ice.zero.server.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.time.Duration;
import java.time.temporal.ChronoUnit;

/**
 * @author DaoDao
 */
@Configuration
public class CorsConfig {

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = config();
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }

    public static CorsConfiguration config() {
        CorsConfiguration config = new CorsConfiguration();
        // config.addAllowedOrigin("*");
        config.addAllowedOriginPattern("*");
        config.addAllowedMethod("*");
        config.addAllowedHeader("*");
        config.addExposedHeader("*");
        config.setAllowCredentials(true);
        config.setAllowPrivateNetwork(true);
        config.setMaxAge(Duration.of(3600L, ChronoUnit.SECONDS));
        return config;
    }

}
