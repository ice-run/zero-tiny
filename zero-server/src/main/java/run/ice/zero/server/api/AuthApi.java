package run.ice.zero.server.api;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.service.annotation.HttpExchange;
import org.springframework.web.service.annotation.PostExchange;
import run.ice.zero.server.constant.AppConstant;
import run.ice.zero.server.constant.ServerConstant;
import run.ice.zero.server.model.No;
import run.ice.zero.server.model.Ok;
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.oauth2.LoginParam;
import run.ice.zero.server.model.oauth2.TokenData;

/**
 * @author DaoDao
 */
@Tag(name = "AuthApi", description = "OAuth2接口")
@HttpExchange(url = AppConstant.API)
public interface AuthApi {

    @Operation(summary = "用户登录", description = "用户登录")
    @PostExchange(url = "login")
    Response<TokenData> login(@RequestBody @Valid Request<LoginParam> request);

    @Operation(summary = "用户退出", description = "用户退出")
    @SecurityRequirement(name = ServerConstant.BEARER_TOKEN)
    @PostExchange(url = "logout")
    Response<Ok> logout(@RequestBody @Valid Request<No> request);

}
