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
import run.ice.zero.server.model.*;
import run.ice.zero.server.model.user.UserData;
import run.ice.zero.server.model.user.UserSearch;
import run.ice.zero.server.model.user.UserUpdate;
import run.ice.zero.server.model.user.UserUpsert;

/**
 * @author DaoDao
 */
@Tag(name = "UserApi", description = "用户接口")
@SecurityRequirement(name = ServerConstant.BEARER_TOKEN)
@HttpExchange(url = AppConstant.API)
public interface UserApi {

    @Operation(summary = "用户信息", description = "获取当前登录的用户信息")
    @PostExchange(url = ServerConstant.USER_INFO)
    Response<UserData> userInfo(@RequestBody @Valid Request<No> request);

    @Operation(summary = "用户更新", description = "用户更新自己的信息")
    @PostExchange(url = ServerConstant.USER_UPDATE)
    Response<UserData> userUpdate(@RequestBody @Valid Request<UserUpdate> request);

    @Operation(summary = "查询用户", description = "传入 id 查询用户信息")
    @PostExchange(url = ServerConstant.USER_SELECT)
    Response<UserData> userSelect(@RequestBody @Valid Request<IdParam> request);

    @Operation(summary = "写入用户", description = "传入用户信息，新增或更新一个用户")
    @PostExchange(url = ServerConstant.USER_UPSERT)
    Response<UserData> userUpsert(@RequestBody @Valid Request<UserUpsert> request);

    @Operation(summary = "搜索用户", description = "传入用户信息，搜索用户列表")
    @PostExchange(url = ServerConstant.USER_SEARCH)
    Response<PageData<UserData>> userSearch(@RequestBody @Valid Request<PageParam<UserSearch>> request);

}
