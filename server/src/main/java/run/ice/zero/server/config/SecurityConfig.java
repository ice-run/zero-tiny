package run.ice.zero.server.config;

import jakarta.annotation.Resource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import run.ice.zero.server.constant.ServerConstant;
import run.ice.zero.server.filter.TokenAuthenticationFilter;
import run.ice.zero.server.handler.AppAccessDeniedHandler;
import run.ice.zero.server.handler.AppAuthenticationEntryPoint;
import run.ice.zero.server.service.UserService;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Resource
    private AppConfig appConfig;

    @Resource
    private AppAccessDeniedHandler appAccessDeniedHandler;

    @Resource
    private AppAuthenticationEntryPoint appAuthenticationEntryPoint;

    @Resource
    private TokenAuthenticationFilter tokenAuthenticationFilter;

    @Resource
    private UserService userService;

    private static final String[] PERMIT_PATHS = {
            "/",
            "/favicon.ico",
            "/swagger-ui/**",
            "/v3/api-docs/**",
            "/actuator/**",
            "/login",
            "/api/login",
    };

    private static final String[] ADMIN_PATHS = {
            "/api/user-upsert",
    };

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http

                .cors(cors -> cors.configurationSource(request -> CorsConfig.config()))

                .csrf(AbstractHttpConfigurer::disable)

                .sessionManagement(session -> session
//                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                )

                .authorizeHttpRequests(authorize -> authorize
                                .requestMatchers(PERMIT_PATHS)
                                .permitAll()

                                .requestMatchers(ADMIN_PATHS)
                                .hasAuthority(ServerConstant.ADMIN)

                                .anyRequest()
                                .hasAuthority(ServerConstant.USER)

                        // .hasRole("ADMIN")
                        // .authenticated()
                )

                .exceptionHandling(exceptionHandling -> exceptionHandling
                        .authenticationEntryPoint(appAuthenticationEntryPoint)
                        .accessDeniedHandler(appAccessDeniedHandler)
                )

                .formLogin(Customizer.withDefaults())

                .httpBasic(Customizer.withDefaults())

                .userDetailsService(userService)

                .addFilterBefore(tokenAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)

        ;
        return http.build();
    }

}
