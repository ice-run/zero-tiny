package run.ice.zero.server.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 响应成功的空对象数据
 * 响应成功：用于解决空对象参数的序列化和反序列化问题，无实际意义
 *
 * @author DaoDao
 */
@Schema(title = "Ok", description = "空对象数据", example = "{}")
@Data
public class Ok implements Serializer {

    /**
     * 用于解决空对象参数的序列化和反序列化问题，无实际意义
     */
    @Schema(title = "ok", description = "空对象数据", example = "Ok!", accessMode = Schema.AccessMode.READ_ONLY)
    @JsonIgnore
    private String ok = "Ok!";

}
