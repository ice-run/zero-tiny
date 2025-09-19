package run.ice.zero.server.service;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;
import run.ice.zero.server.ZeroServerApplicationTest;

@Slf4j
class UserServiceTest extends ZeroServerApplicationTest {

    @Resource
    private PasswordEncoder passwordEncoder;

    @Test
    void testPasswordEncoder() {
        String password = "admin";
        String encodedPassword = passwordEncoder.encode(password);
        log.info("Encoded password: {}", encodedPassword);
        Assertions.assertTrue(passwordEncoder.matches(password, encodedPassword));
    }

}