package run.ice.zero.server.service;

import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import run.ice.zero.server.entity.User;
import run.ice.zero.server.error.AppError;
import run.ice.zero.server.error.AppException;
import run.ice.zero.server.error.ServerError;
import run.ice.zero.server.helper.HttpHelper;
import run.ice.zero.server.helper.TokenHelper;
import run.ice.zero.server.model.oauth2.LoginParam;
import run.ice.zero.server.model.oauth2.TokenData;
import run.ice.zero.server.repository.UserRepository;

import java.util.Optional;

@Slf4j
@Service
@Transactional
public class AuthService {

    @Resource
    private UserRepository userRepository;

    @Resource
    private PasswordEncoder passwordEncoder;

    @Resource
    private TokenHelper tokenHelper;

    @Resource
    private HttpHelper httpHelper;

    public TokenData login(@Valid @NotNull LoginParam param) {
        String username = param.getUsername();
        String password = param.getPassword();
        Optional<User> optional = userRepository.findByUsername(username);
        if (optional.isEmpty()) {
            throw new AppException(ServerError.USERNAME_NOT_EXIST, username);
        }
        User user = optional.get();
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new AppException(ServerError.PASSWORD_ERROR, password);
        }
        String token = tokenHelper.createToken(username);
        TokenData tokenData = new TokenData();
        tokenData.setToken(token);
        return tokenData;
    }

    public void logout() {
        String authorization = httpHelper.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization == null || authorization.isEmpty()) {
            throw new AppException(AppError.TOKEN_ERROR);
        }
        tokenHelper.removeToken(authorization);
    }

}
