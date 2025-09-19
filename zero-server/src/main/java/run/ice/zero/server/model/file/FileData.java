package run.ice.zero.server.model.file;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;
import run.ice.zero.server.model.Serializer;

/**
 * @author DaoDao
 */
@Schema(title = "FileData", description = "文件信息")
@Data
public class FileData implements Serializer {

    @Schema(title = "id", description = "id", example = "1")
    @NotEmpty
    @Size(min = 1, max = 18)
    @Pattern(regexp = "^[0-9]{1,18}$")
    private String id;

    @Schema(title = "code", description = "文件 code", example = "1")
    @NotEmpty
    @Size(min = 1, max = 16)
    @Pattern(regexp = "^[0-9A-Za-z]{1,16}$")
    private String code;

    @Schema(title = "name", description = "文件名", example = "1")
    @NotEmpty
    private String name;

    @Schema(title = "origin", description = "源文件名", example = "logo.png")
    @NotEmpty
    private String origin;

    @Schema(title = "type", description = "文件类型", example = "image/png")
    @NotEmpty
    private String type;

    @Schema(title = "size", description = "文件大小", example = "1")
    @NotNull
    private Long size;

    @Schema(title = "path", description = "路径", example = "2020/02/20")
    @NotEmpty
    private String path;

}
