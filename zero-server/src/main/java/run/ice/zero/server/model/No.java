package run.ice.zero.server.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 用于空对象参数
 * 用于解决空对象参数的序列化和反序列化问题，无实际意义，其序列化后的字符串明文为 `{}` ，密文则为这个字符串的加密字符串
 *
 * @author DaoDao
 */
@Schema(title = "No", description = "空对象参数", example = "{}")
@Data
public class No implements Serializer {

    /**
     * 用于解决空对象参数的序列化和反序列化问题，无实际意义
     */
    @Schema(title = "no", description = "空对象参数", example = "No!", accessMode = Schema.AccessMode.READ_ONLY)
    @JsonIgnore
    private String no = "No!";

}
