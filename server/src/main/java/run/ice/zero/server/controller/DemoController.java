package run.ice.zero.server.controller;

import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.RestController;
import run.ice.zero.server.api.DemoApi;
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.demo.Cat;
import run.ice.zero.server.model.demo.Dog;
import run.ice.zero.server.service.DemoService;

/**
 * @author DaoDao
 */
@RestController
public class DemoController implements DemoApi {

    @Resource
    private DemoService demoService;

    @Override
    public Response<Dog> demo(Request<Cat> request) {
        Dog dog = demoService.demo(request.getParam());
        return new Response<>(dog);
    }

}
