package run.ice.zero.server.model.security;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import run.ice.zero.server.model.Serializer;

/**
 * @author DaoDao
 */
@Data
@Schema(title = "ChangePassword", description = "修改密码")
public class ChangePassword implements Serializer {

    @Schema(title = "oldPassword", description = "旧密码", example = "1")
    @NotEmpty
    @Size(min = 1, max = 32)
    private String oldPassword;

    @Schema(title = "newPassword", description = "新密码", example = "1")
    @NotEmpty
    @Size(min = 1, max = 32)
    @Pattern(regexp = "^[0-9A-Za-z~`!@#$%^&*()_+\\-=\\[\\]{}|\\\\:;\"'<>,.?/]{1,32}$")
    private String newPassword;

}
