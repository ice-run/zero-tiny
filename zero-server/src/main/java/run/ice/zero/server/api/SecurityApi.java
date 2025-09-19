package run.ice.zero.server.api;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.service.annotation.HttpExchange;
import org.springframework.web.service.annotation.PostExchange;
import run.ice.zero.server.constant.AppConstant;
import run.ice.zero.server.constant.ServerConstant;
import run.ice.zero.server.model.Ok;
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.security.ChangePassword;
import run.ice.zero.server.model.security.ResetPassword;

/**
 * @author DaoDao
 */
@Tag(name = "SecurityApi", description = "安全接口")
@HttpExchange(url = AppConstant.API)
public interface SecurityApi {

    @Operation(summary = "重置密码", description = "输入 用户 id 和 密码，重新设置密码")
    @PostExchange(url = ServerConstant.SECURITY_RESET_PASSWORD)
    Response<Ok> resetPassword(@RequestBody @Valid Request<ResetPassword> request);

    @Operation(summary = "变更密码", description = "输入 新密码和旧密码，设置用户密码")
    @PostExchange(url = ServerConstant.SECURITY_CHANGE_PASSWORD)
    Response<Ok> changePassword(@RequestBody @Valid Request<ChangePassword> request);

}
