package run.ice.zero.server.controller;

import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.RestController;
import run.ice.zero.server.api.OAuth2Api;
import run.ice.zero.server.model.No;
import run.ice.zero.server.model.Ok;
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.oauth2.LoginParam;
import run.ice.zero.server.model.oauth2.TokenData;
import run.ice.zero.server.service.OAuth2Service;

/**
 * @author DaoDao
 */
@RestController
public class OAuth2Controller implements OAuth2Api {

    @Resource
    private OAuth2Service oAuth2Service;

    @Override
    public Response<TokenData> oAuth2Login(Request<LoginParam> request) {
        TokenData data = oAuth2Service.oAuth2Login(request.getParam());
        return new Response<>(data);
    }

    @Override
    public Response<Ok> oAuth2Logout(Request<No> request) {
        oAuth2Service.oAuth2Logout();
        return new Response<>();
    }

}
