package run.ice.zero.server.config;

import lombok.Data;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

/**
 * @author DaoDao
 */
@Data
@Configuration
public class AppConfig {

    @Value("${spring.application.name:}")
    private String application;

    @Value("${app.slogan:}")
    private String slogan;

    @Value("${app.token-duration:P7D}")
    private Duration tokenDuration;

    @Value("${app.file.path:/data/file/}")
    private String filePath;

}
