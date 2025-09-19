package run.ice.zero.server.config;

import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;
import run.ice.zero.server.constant.ServerConstant;

/**
 * @author DaoDao
 */
@Configuration
@SecurityScheme(
        name = ServerConstant.BEARER_TOKEN,
        type = SecuritySchemeType.HTTP,
        scheme = "bearer"
)
public class OpenApiConfig {

}
