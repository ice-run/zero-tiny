package run.ice.zero.server.helper;

import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import run.ice.zero.server.constant.FilterConstant;
import run.ice.zero.server.error.AppError;
import run.ice.zero.server.error.AppException;
import run.ice.zero.server.model.Response;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;

/**
 * @author DaoDao
 */
@Slf4j
@Component
public class FilterHelper {

    @Resource
    private ObjectMapper objectMapper;

    public void responseException(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Response<?> data;
        Object exception = request.getAttribute(FilterConstant.X_EXCEPTION);
        if (null != exception) {
            AppException appException = (AppException) exception;
            data = new Response<>(appException);
        } else if (response.getStatus() == HttpStatus.UNAUTHORIZED.value()) {
            data = new Response<>(new AppException(AppError.TOKEN_ERROR));
        } else if (response.getStatus() == HttpStatus.FORBIDDEN.value()) {
            data = new Response<>(new AppException(AppError.PERMISSION_ERROR));
        } else {
            data = new Response<>(new AppException(AppError.UNKNOWN_ERROR));
        }
        response.setStatus(HttpStatus.OK.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.getWriter().write(objectMapper.writeValueAsString(data));
    }

}
