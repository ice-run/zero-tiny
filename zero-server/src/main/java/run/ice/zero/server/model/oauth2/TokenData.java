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
@Schema(title = "TokenData", description = "Token 数据")
@Data
public class TokenData implements Serializer {

    @Schema(title = "Token", description = "Token", example = "...")
    @NotEmpty
    @Size(min = 36, max = 36)
    @Pattern(regexp = "^[a-zA-Z0-9-]{36}$")
    private String token;

}
