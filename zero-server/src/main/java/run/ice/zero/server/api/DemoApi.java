package run.ice.zero.server.api;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.service.annotation.HttpExchange;
import org.springframework.web.service.annotation.PostExchange;
import run.ice.zero.server.constant.AppConstant;
import run.ice.zero.server.constant.ServerConstant;
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.demo.Cat;
import run.ice.zero.server.model.demo.Dog;

/**
 * @author DaoDao
 */
@Tag(name = "DemoApi", description = "示例")
@HttpExchange(url = AppConstant.API)
public interface DemoApi {

    @Operation(summary = "demo", description = "示例接口")
    @PostExchange(url = ServerConstant.DEMO)
    Response<Dog> demo(@RequestBody @Valid Request<Cat> request);

}
