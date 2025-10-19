package run.ice.zero.server.controller;

import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.RestController;
import run.ice.zero.server.api.UserApi;
import run.ice.zero.server.model.*;
import run.ice.zero.server.model.user.UserData;
import run.ice.zero.server.model.user.UserSearch;
import run.ice.zero.server.model.user.UserUpdate;
import run.ice.zero.server.model.user.UserUpsert;
import run.ice.zero.server.service.UserService;

/**
 * @author DaoDao
 */
@RestController
public class UserController implements UserApi {

    @Resource
    private UserService userService;

    @Override
    public Response<UserData> userInfo(Request<No> request) {
        UserData data = userService.userInfo();
        return new Response<>(data);
    }

    @Override
    public Response<UserData> userUpdate(Request<UserUpdate> request) {
        UserData data = userService.userUpdate(request.getParam());
        return new Response<>(data);
    }

    @Override
    public Response<UserData> userSelect(Request<IdParam> request) {
        UserData data = userService.userSelect(request.getParam());
        return new Response<>(data);
    }

    @Override
    public Response<UserData> userUpsert(Request<UserUpsert> request) {
        UserData data = userService.userUpsert(request.getParam());
        return new Response<>(data);
    }

    @Override
    public Response<PageData<UserData>> userSearch(Request<PageParam<UserSearch>> request) {
        PageData<UserData> data = userService.userSearch(request.getParam());
        return new Response<>(data);
    }

}
