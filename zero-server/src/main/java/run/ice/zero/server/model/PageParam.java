package run.ice.zero.server.model;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 带有分页条件的查询参数
 *
 * @author DaoDao
 */
@Schema(title = "PageParam", description = "带有分页条件的查询")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageParam<P> implements Serializer {

    /**
     * 当前页码
     * 起始页为 1
     */
    @Schema(title = "page", description = "页码，>= 1 ，起始页 = 1，default = 1", example = "1")
    @Min(value = 1)
    @Max(value = Integer.MAX_VALUE)
    private Integer page = 1;

    /**
     * 分页步长（每页数量）
     * > 0
     */
    @Schema(title = "size", description = "分页步长，> 0 ，default = 10 , max = 1000", example = "10")
    @Min(value = 1)
    @Max(value = 1000)
    private Integer size = 10;

    @Schema(title = "param", description = "查询参数，not null")
    @Valid
    @NotNull
    private P param;

    @Schema(title = "matches", description = "匹配条件")
    @Valid
    private List<Match> matches;

    @Schema(title = "orders", description = "排序条件")
    @Valid
    private List<Order> orders;

    public PageParam(P param) {
        this.param = param;
    }

    @Data
    public static class Match {

        @Schema(title = "property", description = "属性", example = "id")
        @Size(min = 1, max = 64)
        @NotEmpty
        private String property;

        @Schema(title = "mode", description = "匹配模式", example = "EXACT")
        @NotNull
        // @Pattern(regexp = "^(EXACT|CONTAIN|REGEX)$")
        private Mode mode = Mode.EXACT;

        public static Match of(String property) {
            Match match = new Match();
            match.setProperty(property);
            match.setMode(Mode.EXACT);
            return match;
        }

        public static Match of(String property, Mode mode) {
            Match match = new Match();
            match.setProperty(property);
            match.setMode(mode);
            return match;
        }

        public enum Mode {
            EXACT, CONTAIN, REGEX,
        }

    }

    @Data
    public static class Order {

        @Schema(title = "property", description = "属性", example = "id")
        @Size(min = 1, max = 64)
        @NotEmpty
        private String property;

        @Schema(title = "direction", description = "方向", example = "ASC")
        @NotNull
        // @Pattern(regexp = "^(ASC|DESC)$")
        private Direction direction = Direction.ASC;

        public static Order by(String property) {
            Order order = new Order();
            order.setProperty(property);
            order.setDirection(Direction.ASC);
            return order;
        }

        public static Order by(String property, Direction direction) {
            Order order = new Order();
            order.setProperty(property);
            order.setDirection(direction);
            return order;
        }

        public enum Direction {
            ASC, DESC
        }

    }

}
