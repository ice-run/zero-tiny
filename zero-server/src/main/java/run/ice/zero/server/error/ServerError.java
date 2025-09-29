package run.ice.zero.server.error;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * @author DaoDao
 */
@Getter
@AllArgsConstructor
public enum ServerError implements ErrorEnum {

    ERROR("1000", "server 服务异常"),
    USERNAME_NOT_EXIST("1001", "用户名不存在"),
    PASSWORD_ERROR("1002", "密码错误"),
    USER_NOT_EXIST("1003", "用户不存在"),
    USERNAME_NOT_NULL("1004", "用户名不能为空"),
    USERNAME_ALREADY_EXIST("1005", "用户名已存在"),
    OLD_AND_NEW_PASSWORDS_CANNOT_BE_THE_SAME("1006", "新旧密码不能相同"),
    OLD_PASSWORD_INCORRECT("1007", "旧密码不正确"),
    FILE_READ_WRITE_ERROR("1008", "文件读写异常"),
    FILE_CODE_ERROR("1009", "文件编码错误"),
    FILE_NOT_EXIST("1010", "文件不存在"),

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
