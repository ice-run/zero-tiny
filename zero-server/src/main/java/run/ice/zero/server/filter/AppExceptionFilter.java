package run.ice.zero.server.filter;

import jakarta.annotation.Resource;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import run.ice.zero.server.error.AppException;
import run.ice.zero.server.helper.FilterHelper;

import java.io.IOException;

/**
 * @author DaoDao
 */
@Slf4j
@Order(-2)
@Component
public class AppExceptionFilter implements Filter {

    @Resource
    private FilterHelper filterHelper;

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        try {
            chain.doFilter(request, response);
        } catch (AppException e) {
            log.error(e.getMessage(), e);
            filterHelper.responseException((HttpServletRequest) request, (HttpServletResponse) response);
        }
    }

}
