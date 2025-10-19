package run.ice.zero.server.controller;

import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.RestController;
import run.ice.zero.server.api.SecurityApi;
import run.ice.zero.server.model.Ok;
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.security.ChangePassword;
import run.ice.zero.server.model.security.ResetPassword;
import run.ice.zero.server.service.SecurityService;

/**
 * @author DaoDao
 */
@RestController
public class SecurityController implements SecurityApi {

    @Resource
    private SecurityService securityService;

    @Override
    public Response<Ok> resetPassword(Request<ResetPassword> request) {
        securityService.resetPassword(request.getParam());
        return Response.ok();
    }

    @Override
    public Response<Ok> changePassword(Request<ChangePassword> request) {
        securityService.changePassword(request.getParam());
        return Response.ok();
    }

}
