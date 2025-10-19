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
import run.ice.zero.server.model.Request;
import run.ice.zero.server.model.Response;
import run.ice.zero.server.model.file.FileData;
import run.ice.zero.server.model.file.FileParam;

/**
 * @author DaoDao
 */
@Tag(name = "文件", description = "文件接口")
@HttpExchange(url = AppConstant.API)
public interface FileApi {

    @Operation(summary = "info 文件信息", description = "传入文件 id，查询文件信息")
    @SecurityRequirement(name = ServerConstant.BEARER_TOKEN)
    @PostExchange(url = "file-info")
    Response<FileData> info(@RequestBody @Valid Request<FileParam> request);

}
