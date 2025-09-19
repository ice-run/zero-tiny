package run.ice.zero.server.model;

import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.ext.javatime.ser.LocalDateSerializer;
import tools.jackson.databind.ext.javatime.ser.LocalDateTimeSerializer;
import tools.jackson.databind.ext.javatime.ser.LocalTimeSerializer;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

public interface Serializer extends Serializable {

    ObjectMapper objectMapper = new ObjectMapper();
//            .registerModule(new JavaTimeModule()
//                    .addSerializer(LocalDate.class, new LocalDateSerializer(DateTimeFormatter.ISO_LOCAL_DATE))
//                    .addSerializer(LocalTime.class, new LocalTimeSerializer(DateTimeFormatter.ISO_LOCAL_TIME))
//                    .addSerializer(LocalDateTime.class, new LocalDateTimeSerializer(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
//            )
//            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            ;

    default String toJson() {
        String json;
        try {
            json = objectMapper.writeValueAsString(this);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return json;
    }

    static String toJson(Object o) {
        String json;
        try {
            json = objectMapper.writeValueAsString(o);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return json;
    }

    /**
     * 此方法不支持泛型，泛型请使用 {@link #ofJson(String, TypeReference)}
     *
     * @param <T>  T
     * @param json json
     * @return T
     */
    @SuppressWarnings("unchecked")
    default <T> T ofJson(String json) {
        if (json == null) {
            return null;
        }
        T t;
        Class<? extends Serializer> clazz = this.getClass();
        try {
            t = (T) objectMapper.readValue(json, clazz);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return t;
    }

    static <T> T ofJson(String json, TypeReference<T> typeReference) {
        if (json == null) {
            return null;
        }
        T t;
        try {
            t = objectMapper.readValue(json, typeReference);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return t;
    }

    static <T> T convert(Object o, TypeReference<T> typeReference) {
        T t;
        try {
            t = objectMapper.convertValue(o, typeReference);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        return t;
    }

}
