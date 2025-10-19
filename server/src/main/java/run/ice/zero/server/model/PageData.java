package run.ice.zero.server.model;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 带有分页信息的数据响应
 *
 * @author DaoDao
 */
@Schema(title = "PageData", description = "带有分页信息的数据响应")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageData<D> implements Serializer {

    /**
     * 当前页码
     * 起始页为 1
     */
    @Schema(title = "page", description = "页码：>= 1 ，起始页 = 1", example = "1")
    @NotNull
    private Integer page;

    /**
     * 分页步长（每页数量）
     * > 0
     */
    @Schema(title = "size", description = "步长：分页步长，> 0", example = "10")
    @NotNull
    private Integer size;

    /**
     * 总条数
     */
    @Schema(title = "total", description = "总数：所有分页的总条数", example = "100")
    @NotNull
    private Long total;

    @Schema(title = "head", description = "表头：有序键值对，key = value，key 为表头的字段名称，value 为表头的字段描述。均为 String 类型")
    private Map<String, String> head;

    /**
     * 数据列表
     */
    @Schema(title = "list", description = "列表：数据列表")
    @NotNull
    private List<D> list;

    public PageData(@NotNull Integer page, @NotNull Integer size, @NotNull Long total, @NotNull List<D> list) {
        this.page = page;
        this.size = size;
        this.total = total;
        this.list = list;
    }

    @SuppressWarnings("unchecked")
    public Map<String, String> getHead() {
        if (null != head && !head.isEmpty()) {
            return head;
        }
        if (null == list || list.isEmpty()) {
            return Map.of();
        }
        D d = list.getFirst();
        Class<D> clazz = (Class<D>) d.getClass();
        if (d instanceof Serializer) {
            return ofHead((Class<? extends Serializer>) clazz);
        }
        return Map.of();
    }

    public static <D extends Serializer> Map<String, String> ofHead(Class<D> clazz) {
        Map<String, String> head = new LinkedHashMap<>();
        Arrays.stream(clazz.getDeclaredFields()).map(field -> {
            String key = field.getName();
            String value = field.getName();
            Schema schema = field.getAnnotation(Schema.class);
            if (null != schema) {
                String title = schema.title();
                if (null != title && !title.isEmpty()) {
                    value = title;
                }
            }
            return Map.entry(key, value);
        }).forEach((entry) -> {
            head.put(entry.getKey(), entry.getValue());
        });
        return head;
    }

}
