package run.ice.zero.server.util;

import lombok.extern.slf4j.Slf4j;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

@Slf4j
public class FileUtil {

    public static String contentType(File file) {
        String type = null;
        try {
            type = Files.probeContentType(file.toPath());
        } catch (IOException e) {
            log.error(e.getMessage(), e);
        }
        if (null == type) {
            type = "application/octet-stream";
        }
        return type;
    }

    public static String extension(String fileName) {
        if (null == fileName || fileName.isEmpty()) {
            return null;
        }
        int beginIndex = fileName.lastIndexOf(".");
        if (-1 == beginIndex) {
            return null;
        }
        int endIndex = fileName.length();
        String extension = fileName.substring(beginIndex + 1, endIndex);
        return extension.toLowerCase();
    }

}
