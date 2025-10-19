package run.ice.zero.server.service;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import run.ice.zero.server.entity.User;
import run.ice.zero.server.error.AppException;
import run.ice.zero.server.error.ServerError;
import run.ice.zero.server.model.security.ChangePassword;
import run.ice.zero.server.model.security.ResetPassword;
import run.ice.zero.server.repository.UserRepository;

import java.util.Optional;

@Slf4j
@Service
@Transactional
public class SecurityService {

    @Resource
    private UserRepository userRepository;

    @Resource
    private PasswordEncoder passwordEncoder;

    public void resetPassword(ResetPassword param) {
        Long id = param.getId();
        String password = param.getPassword();
        Optional<User> optional = userRepository.findById(id);
        if (optional.isEmpty()) {
            throw new AppException(ServerError.USER_NOT_EXIST, String.valueOf(id));
        }
        User user = optional.get();
        if (null == password || password.isEmpty()) {
            password = user.getUsername();
        }
        user.setPassword(passwordEncoder.encode(password));
        userRepository.save(user);
    }

    public void changePassword(ChangePassword param) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        Optional<User> optional = userRepository.findByUsername(username);
        if (optional.isEmpty()) {
            throw new AppException(ServerError.USER_NOT_EXIST, username);
        }
        User user = optional.get();
        String oldPassword = param.getOldPassword();
        String newPassword = param.getNewPassword();
        if (oldPassword.equals(newPassword)) {
            throw new AppException(ServerError.OLD_AND_NEW_PASSWORDS_CANNOT_BE_THE_SAME, param.toJson());
        }
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new AppException(ServerError.OLD_PASSWORD_INCORRECT, oldPassword);
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

}
