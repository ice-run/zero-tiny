package run.ice.zero.server.handler;

import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;
import run.ice.zero.server.constant.AppConstant;
import run.ice.zero.server.constant.FilterConstant;
import run.ice.zero.server.helper.FilterHelper;

import java.io.IOException;

/**
 * @author DaoDao
 */
@Component
public class AppAccessDeniedHandler implements AccessDeniedHandler {

    @Resource
    private FilterHelper filterHelper;

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException accessDeniedException) throws IOException {
        response.setStatus(HttpStatus.FORBIDDEN.value());
        Object originUri = request.getAttribute(FilterConstant.X_ORIGIN_URI);
        if (null != originUri && ((String) originUri).startsWith("/" + AppConstant.API + "/")) {
            filterHelper.responseException(request, response);
        }
    }

}
