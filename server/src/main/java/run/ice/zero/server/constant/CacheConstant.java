package run.ice.zero.server.constant;

public class CacheConstant {

    private static final String DELIMITER = ":";

    private static final String PREFIX = AppConstant.NAMESPACE + DELIMITER + "server" + DELIMITER;

    public static final String TOKEN = PREFIX + "token" + DELIMITER;

    public static final String USER = PREFIX + "user" + DELIMITER;

    public static final String FILE_INFO = PREFIX + "file" + DELIMITER + "info" + DELIMITER;

}
