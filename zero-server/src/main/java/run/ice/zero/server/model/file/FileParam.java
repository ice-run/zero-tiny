package run.ice.zero.server.model.file;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import run.ice.zero.server.model.Serializer;

/**
 * @author DaoDao
 */
@Schema(title = "FileParam", description = "文件")
@Data
public class FileParam implements Serializer {

    @Schema(title = "id", description = "文件 ID", example = "1")
    @NotEmpty
    @Size(min = 1, max = 18)
    @Pattern(regexp = "^[0-9]{1,18}$")
    private String id;

    @Schema(title = "code", description = "文件 code", example = "1")
    @NotEmpty
    @Size(min = 1, max = 16)
    @Pattern(regexp = "^[0-9A-Za-z]{1,16}$")
    private String code;

}
