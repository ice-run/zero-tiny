package run.ice.zero.server.error;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * @author DaoDao
 */
@Getter
@AllArgsConstructor
public enum AppError implements ErrorEnum {

    /**
     * OK
     * 现在约定 OK 0000 为请求成功
     */
    OK("0000", "OK"),

    /**
     * 全局异常
     */
    ERROR("9999", "ERROR"),

    /**
     * token 错误
     */
    TOKEN_ERROR("1111", "token 错误"),

    /**
     * 权限错误
     */
    PERMISSION_ERROR("2222", "权限错误"),

    /**
     * 请求参数错误
     */
    REQUEST_PARAM_ERROR("6666", "请求参数错误"),

    /**
     * 未知异常
     */
    UNKNOWN_ERROR("8888", "未知异常"),

    ;

    /**
     * 错误编码
     */
    public final String code;

    /**
     * 错误信息
     */
    public final String message;

}
