package run.ice.zero.server.controller;

import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.RestController;
import run.ice.zero.server.api.IndexApi;
import run.ice.zero.server.config.AppConfig;
import run.ice.zero.server.constant.AppConstant;

/**
 * @author DaoDao
 */
@RestController
public class IndexController implements IndexApi {

    @Resource
    private AppConfig appConfig;

    public String index() {
        String slogan = appConfig.getSlogan();
        return (null != slogan && !slogan.isEmpty()) ? slogan : AppConstant.SLOGAN;
    }

}
