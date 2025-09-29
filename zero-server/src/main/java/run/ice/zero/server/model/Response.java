package run.ice.zero.server.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;
import run.ice.zero.server.error.AppError;
import run.ice.zero.server.error.AppException;
import run.ice.zero.server.error.ErrorEnum;

/**
 * @author DaoDao
 */
@Schema(title = "Response", description = "响应", accessMode = Schema.AccessMode.READ_ONLY)
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Response<D> implements Serializer {

    /**
     * `0000` 表示成功，其他表示异常
     */
    @Schema(title = "code", description = "响应编码，4 位数字字符串", example = "0000", accessMode = Schema.AccessMode.READ_ONLY)
    @NotEmpty
    @Size(min = 4, max = 4)
    @Pattern(regexp = "^[0-9]{4}$")
    private String code = AppError.OK.code;

    /**
     * 如果发生异常，通常会展示具体的异常提示
     */
    @Schema(title = "message", description = "响应信息，字符串", example = "成功", accessMode = Schema.AccessMode.READ_ONLY)
    @NotEmpty
    @Size(min = 1, max = 255)
    private String message = AppError.OK.message;

    /**
     * 通常为复杂的数据对象
     * - 明文为数据对象的 json 格式
     * - 密文则为对象的 json 序列化的字符串的加密字符串
     * - 如果对象为空（不需要返回具体的数据内容），请传递空对象
     * - 空对象的序列化后的字符串明文为 `{}` ，密文则为这个字符串的加密字符串
     */
    @Schema(title = "data", description = "响应数据", accessMode = Schema.AccessMode.READ_ONLY)
    @Valid
    private D data;

    public Response(D data) {
        this.data = data;
    }

    public Response(@NonNull String code, @NonNull String message) {
        this.code = code;
        this.message = message;
    }

    public <E extends AppException> Response(@NonNull E e) {
        this.code = e.getCode();
        this.message = e.getMessage();
    }

    public <E extends Enum<E> & ErrorEnum> Response(@NonNull E e) {
        this.code = e.getCode();
        this.message = e.getMessage();
    }

    public static Response<Ok> ok() {
        Ok ok = new Ok();
        return new Response<>(ok);
    }

    public static <D> Response<D> of(D data) {
        return new Response<>(data);
    }

    @JsonIgnore
    public Boolean isOk() {
        return AppError.OK.code.equals(this.code); // && null != this.data
    }

    public static <D> Boolean isOk(Response<D> response) {
        return null != response && response.isOk();
    }

}
