package run.ice.zero.server.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * @author DaoDao
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "app.logger")
public class LoggerConfig {

    private List<String> excludeUrls;

}
