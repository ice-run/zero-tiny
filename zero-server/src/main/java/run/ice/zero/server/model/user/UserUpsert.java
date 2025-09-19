package run.ice.zero.server.model.user;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import run.ice.zero.server.model.Serializer;
import tools.jackson.databind.annotation.JsonSerialize;
import tools.jackson.databind.ser.std.ToStringSerializer;

/**
 * @author DaoDao
 */
@Data
@Schema(title = "UserUpsert", description = "用户写入：若 id 有值，则更新，否则新增")
public class UserUpsert implements Serializer {

    @Schema(title = "ID", description = "用户 ID", example = "1")
    @Min(value = 1)
    @Max(value = Long.MAX_VALUE)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Schema(title = "username", description = "用户名", example = "admin")
    @Size(min = 1, max = 32)
    @Pattern(regexp = "^[a-zA-Z0-9-_.]{1,32}$")
    private String username;

    @Schema(title = "nickname", description = "昵称", example = "嘟嘟")
    @Size(min = 1, max = 32)
    private String nickname;

    @Schema(title = "valid", description = "是否有效", example = "true")
    private Boolean valid;

}
