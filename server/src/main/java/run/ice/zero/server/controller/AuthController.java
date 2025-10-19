package run.ice.zero.server.controller;

import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.RestController;
import run.ice.zero.server.api.AuthApi;
import run.ice.zero.server.model.No;
import run.ice.zero.server.model.Ok;
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.oauth2.LoginParam;
import run.ice.zero.server.model.oauth2.TokenData;
import run.ice.zero.server.service.AuthService;

/**
 * @author DaoDao
 */
@RestController
public class AuthController implements AuthApi {

    @Resource
    private AuthService authService;

    @Override
    public Response<TokenData> login(Request<LoginParam> request) {
        TokenData data = authService.login(request.getParam());
        return new Response<>(data);
    }

    @Override
    public Response<Ok> logout(Request<No> request) {
        authService.logout();
        return new Response<>();
    }

}
