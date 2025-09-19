package run.ice.zero.server.helper;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;
import run.ice.zero.server.config.AppConfig;
import run.ice.zero.server.constant.CacheConstant;
import run.ice.zero.server.error.AppError;
import run.ice.zero.server.error.AppException;

import java.time.Duration;
import java.util.UUID;

/**
 * @author DaoDao
 */
@Slf4j
@Component
public class TokenHelper {

    @Resource
    private AppConfig appConfig;

    @Resource
    private StringRedisTemplate stringRedisTemplate;

    public String username(String authorization) {
        String token = extractToken(authorization);
        String key = CacheConstant.TOKEN + token;
        String username = stringRedisTemplate.opsForValue().get(key);
        if (username.isEmpty()) {
            throw new AppException(AppError.TOKEN_ERROR, token);
        }
        return username;
    }

    public String createToken(String username) {
        String token = generateToken();
        String key = CacheConstant.TOKEN + token;
        Duration duration = appConfig.getTokenDuration();
        stringRedisTemplate.opsForValue().set(key, username, duration);
        return token;
    }

    public void removeToken(String authorization) {
        String token = extractToken(authorization);
        String key = CacheConstant.TOKEN + token;
        String username = stringRedisTemplate.opsForValue().get(key);
        if (username.isEmpty()) {
            log.warn("Token not found: {}", token);
            // throw new AppException(AppError.TOKEN_ERROR, token);
        }
        stringRedisTemplate.delete(key);
    }

    public void renewToken(String authorization) {
        String token = extractToken(authorization);
        String key = CacheConstant.TOKEN + token;
        String username = stringRedisTemplate.opsForValue().get(key);
        if (username.isEmpty()) {
            throw new AppException(AppError.TOKEN_ERROR, token);
        }
        Duration duration = appConfig.getTokenDuration();
        stringRedisTemplate.opsForValue().set(key, username, duration);
    }

    private static String extractToken(String authorization) {
        return authorization.replace("Bearer ", "");
    }

    private static String generateToken() {
        return UUID.randomUUID().toString();
    }

}
