package run.ice.zero.server.util;

import java.math.BigInteger;
import java.util.Arrays;

/**
 * 进制转换工具类
 *
 * @author DaoDao
 */
public class RadixUtil {

    private static final char[] CHARS = {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
            'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
            'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
            'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
            'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
            'y', 'z',
    };

    /**
     * 进制转换
     *
     * @param string 源字符串
     * @param from   源进制
     * @param to     目标进制
     * @return 目标字符串
     */
    public static String convert(String string, int from, int to) {
        Boolean b = check(string, from, to);
        if (!b) {
            return null;
        }
        char[] chars = Arrays.copyOf(CHARS, from);
        char[] ch = string.toCharArray();
        BigInteger number = BigInteger.ZERO;
        for (int i = 0, j = ch.length - 1; i < ch.length && j >= 0; i++, j--) {
            int x = Arrays.binarySearch(chars, ch[i]);
            BigInteger d = BigInteger.valueOf(from).pow(j);
            number = number.add(d.multiply(BigInteger.valueOf(x)));
        }
        if (number.equals(BigInteger.ZERO)) {
            return "0";
        }
        StringBuilder sb = new StringBuilder();
        while (number.compareTo(BigInteger.ZERO) > 0) {
            BigInteger[] divided = number.divideAndRemainder(BigInteger.valueOf(to));
            sb.insert(0, CHARS[divided[1].intValue()]);
            number = divided[0];
        }
        return sb.toString();
    }

    /**
     * 校验进制转换参数是否正常
     *
     * @param string 源 N 进制的字符串
     * @param from   源字符串 进制
     * @param to     目标字符串 进制
     * @return 参数是否正常
     */
    private static Boolean check(String string, int from, int to) {
        /*
         * 0. 判断 string 是否有效
         */
        if (null == string || string.isEmpty()) {
            return false;
        }
        /*
         * 1. 判断进制参数是否在可用范围之内
         */
        if (from <= 0 || from > CHARS.length || to <= 0 || to > CHARS.length) {
            return false;
        }
        /*
         * 2. 判断字符串字符，是否超出了进制转换范围
         */
        char[] chars = Arrays.copyOf(CHARS, from);
        char[] ch = string.toCharArray();
        for (char c : ch) {
            int i = Arrays.binarySearch(chars, c);
            if (i < 0) {
                return false;
            }
        }
        return true;
    }

}
