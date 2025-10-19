package run.ice.zero.server.model.user;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import lombok.Data;
import run.ice.zero.server.constant.AppConstant;
import run.ice.zero.server.model.Serializer;
import tools.jackson.databind.annotation.JsonSerialize;
import tools.jackson.databind.ser.std.ToStringSerializer;

import java.time.LocalDateTime;

/**
 * @author DaoDao
 */
@Schema(title = "UserData", description = "用户数据")
@Data
public class UserData implements Serializer {

    @Schema(title = "id", description = "id", example = "1")
    @NotNull
    @Min(value = 1)
    @Max(value = Long.MAX_VALUE)
    @JsonSerialize(using = ToStringSerializer.class)
    private Long id;

    @Schema(title = "用户名", description = "用户名", example = "admin")
    @NotEmpty
    @Size(min = 1, max = 32)
    @Pattern(regexp = "^[a-zA-Z0-9-_.]{1,32}$")
    private String username;

    @Schema(title = "昵称", description = "昵称", example = "嘟嘟")
    @Size(min = 1, max = 32)
    private String nickname;

    @Schema(title = "头像", description = "头像", example = "https://example.com/avatar.jpg")
    @Size(min = 1, max = 128)
    private String avatar;

    @Schema(title = "创建时间", description = "创建时间", example = AppConstant.DATE_TIME_EXAMPLE)
    @NotNull
    private LocalDateTime createTime;

    @Schema(title = "创建时间", description = "创建时间", example = AppConstant.DATE_TIME_EXAMPLE)
    @NotNull
    private LocalDateTime updateTime;

    @Schema(title = "valid", description = "状态 true 有效（启用） false 无效（停用）", example = "true")
    @NotNull
    private Boolean valid;

}
