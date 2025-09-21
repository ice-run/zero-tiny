package run.ice.zero.server.util;

import java.beans.BeanInfo;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.util.Arrays;

public class BeanUtil {

    /**
     * 获取属性中为空的字段
     *
     * @param o Object
     * @return String[]
     */
    public static String[] nullProperties(Object o) {
        try {
            BeanInfo beanInfo = Introspector.getBeanInfo(o.getClass());
            PropertyDescriptor[] propertyDescriptors = beanInfo.getPropertyDescriptors();

            return Arrays.stream(propertyDescriptors)
                    .filter(pd -> {
                        try {
                            return pd.getReadMethod() != null && pd.getReadMethod().invoke(o) == null;
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    })
                    .map(PropertyDescriptor::getName)
                    .toArray(String[]::new);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

}
