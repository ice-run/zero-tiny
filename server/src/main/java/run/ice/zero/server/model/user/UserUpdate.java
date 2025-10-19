package run.ice.zero.server.model.user;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Size;
import lombok.Data;
import run.ice.zero.server.model.Serializer;

/**
 * @author DaoDao
 */
@Data
@Schema(title = "UserUpdate", description = "用户更新")
public class UserUpdate implements Serializer {

    @Schema(title = "nickname", description = "昵称", example = "嘟嘟")
    @Size(min = 1, max = 32)
    private String nickname;

    @Schema(title = "avatar", description = "头像", example = "0000")
    @Size(min = 1, max = 32)
    private String avatar;

}
