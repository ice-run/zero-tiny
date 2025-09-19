package run.ice.zero.server.error;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * @author DaoDao
 */
@Getter
@AllArgsConstructor
public enum ServerError implements ErrorEnum {

    ERROR("100000", "server 服务异常"),
    USERNAME_NOT_EXIST("100001", "用户名不存在"),
    PASSWORD_ERROR("100002", "密码错误"),
    USER_NOT_EXIST("100003", "用户不存在"),
    USERNAME_NOT_NULL("100004", "用户名不能为空"),
    USERNAME_ALREADY_EXIST("100005", "用户名已存在"),
    OLD_AND_NEW_PASSWORDS_CANNOT_BE_THE_SAME("100006", "新旧密码不能相同"),
    OLD_PASSWORD_INCORRECT("100007", "旧密码不正确"),
    FILE_READ_WRITE_ERROR("100008", "文件读写异常"),
    FILE_CODE_ERROR("100009", "文件编码错误"),
    FILE_NOT_EXIST("100010", "文件不存在"),

    ;

    /**
     * 响应编码
     */
    public final String code;

    /**
     * 响应说明
     */
    public final String message;

}
