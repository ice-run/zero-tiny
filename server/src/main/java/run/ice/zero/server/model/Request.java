package run.ice.zero.server.model;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.NonNull;

/**
 * @author DaoDao
 */
@Schema(title = "Request", description = "请求")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Request<P> implements Serializer {

    /**
     * 通常为复杂的参数对象
     * - 明文为参数对象的 json 格式
     * - 密文则为对象的 json 序列化的字符串的加密字符串
     * - 如果对象为空（不需传递具体的参数数据），请传递空对象
     * - 空对象的序列化后的字符串明文为 `{}` ，密文则为这个字符串的加密字符串
     */
    @Schema(title = "param", description = "参数", requiredMode = Schema.RequiredMode.REQUIRED)
    @Valid
    @NotNull
    private P param;

    public static Request<No> no() {
        No no = new No();
        return new Request<>(no);
    }

    public static <P> Request<P> of(@NonNull P param) {
        return new Request<>(param);
    }

}
