package run.ice.zero.server.model.oauth2;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import run.ice.zero.server.model.Serializer;

/**
 * @author DaoDao
 */
@Schema(title = "LoginParam", description = "登录参数")
@Data
public class LoginParam implements Serializer {

    @Schema(title = "用户名", description = "用户名", example = "admin")
    @NotEmpty
    @Size(min = 1, max = 32)
    @Pattern(regexp = "^[a-zA-Z0-9-_.]{1,32}$")
    private String username;

    @Schema(title = "用户密码", description = "用户密码", example = "admin")
    @NotEmpty
    @Size(min = 1, max = 32)
    @Pattern(regexp = "^[0-9A-Za-z~`!@#$%^&*()_+\\-=\\[\\]{}|\\\\:;\"'<>,.?/]{1,32}$")
    private String password;

}
