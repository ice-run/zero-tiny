package run.ice.zero.server.model.demo;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;
import run.ice.zero.server.model.Serializer;

/**
 * @author DaoDao
 */
@Data
@Schema(title = "Dog", description = "狗")
public class Dog implements Serializer {

    @Schema(title = "名字", description = "可爱的汪", example = "汪汪")
    @NotEmpty
    @Size(min = 1, max = 255)
    private String name;

}
