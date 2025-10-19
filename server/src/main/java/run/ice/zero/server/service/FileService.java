package run.ice.zero.server.service;

import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.data.domain.Example;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import run.ice.zero.server.config.AppConfig;
import run.ice.zero.server.constant.CacheConstant;
import run.ice.zero.server.entity.FileInfo;
import run.ice.zero.server.error.AppException;
import run.ice.zero.server.error.ServerError;
import run.ice.zero.server.model.file.FileData;
import run.ice.zero.server.model.file.FileParam;
import run.ice.zero.server.repository.FileInfoRepository;
import run.ice.zero.server.util.FileUtil;
import run.ice.zero.server.util.RadixUtil;

import java.io.*;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

@Slf4j
@Service
@Transactional
public class FileService {

    @Resource
    private AppConfig appConfig;

    @Resource
    private StringRedisTemplate stringRedisTemplate;

    @Resource
    private FileInfoRepository fileInfoRepository;

    public FileData info(FileParam param) {
        String id = param.getId();
        String code = param.getCode();
        String x = RadixUtil.convert(id, 10, 62);
        if (!code.equals(x)) {
            throw new AppException(ServerError.FILE_CODE_ERROR, param.toJson());
        }
        FileData data = new FileData();
        String key = CacheConstant.FILE_INFO + id;
        String json = stringRedisTemplate.opsForValue().get(key);
        FileInfo fileInfo;
        if (null != json && !json.isEmpty()) {
            fileInfo = new FileInfo().ofJson(json);
        } else {
            fileInfo = new FileInfo();
            fileInfo.setId(id);
            fileInfo.setValid(Boolean.TRUE);
            Optional<FileInfo> optional = fileInfoRepository.findOne(Example.of(fileInfo));
            if (optional.isEmpty()) {
                throw new AppException(ServerError.FILE_NOT_EXIST, id);
            }
            fileInfo = optional.get();
            stringRedisTemplate.opsForValue().set(key, fileInfo.toJson(), Duration.ofDays(7L));
        }
        BeanUtils.copyProperties(fileInfo, data);
        return data;
    }

    public FileData upload(MultipartFile multipartFile) {
        File file = transfer(multipartFile);
        assert file != null;
        FileInfo fileInfo = store(file);
        fileInfo = fileInfoRepository.save(fileInfo);
        FileData data = new FileData();
        BeanUtils.copyProperties(fileInfo, data);
        return data;
    }

    public File download(FileParam param) {
        FileData data = info(param);
        String root = appConfig.getFilePath();
        String path = data.getPath();
        String name = data.getName();
        File file = new File(root + path + File.separator + name);
        if (file.exists() && file.isFile()) {
            return file;
        } else {
            throw new AppException(ServerError.FILE_NOT_EXIST, param.toJson());
        }
    }

    private File transfer(MultipartFile multipartFile) {
        LocalDateTime localDateTime = LocalDateTime.now();
        String path = localDateTime.format(DateTimeFormatter.ofPattern("yyyy/MM/dd/HHmmss")) + String.format("%09d", localDateTime.getNano());
        String directory = File.separator + "tmp" + File.separator + path;
        File dir = new File(directory);
        if (!dir.exists() || !dir.isDirectory()) {
            boolean b = dir.mkdirs();
            assert b;
        }
        String originalFilename = multipartFile.getOriginalFilename();
        assert originalFilename != null;
        String fileName = originalFilename.replace("/", "_");
        File file = new File(new File(directory).getAbsolutePath() + File.separator + fileName);
        try {
            multipartFile.transferTo(file);
        } catch (IOException e) {
            log.error(e.getMessage(), e);
            return null;
        }
        return file;
    }

    private FileInfo store(File originFile) {
        /*
         * 1. 预定义文件的各项属性
         */
        // 原文件名称
        String origin = originFile.getName();
        // 扩展名
        String extension = FileUtil.extension(origin);
        String ext = (null == extension || extension.isEmpty()) ? "" : ("." + extension);
        // id
        String id = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmssSSS")) + new SecureRandom().nextInt(10);
        String code = RadixUtil.convert(id, 10, 62);
        // time
        LocalDateTime localDateTime = LocalDateTime.now();
        String nano = String.format("%09d", localDateTime.getNano());
        // 根目录
        String root = appConfig.getFilePath();
        // 路径
        String path = localDateTime.format(DateTimeFormatter.ofPattern("yyyy/MM/dd"));
        // 名称
        String name = localDateTime.format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss")) + nano + ext;
        // 目录
        String directory = root + path;
        /*
         * 2. 创建文件目录
         */
        File dir = new File(directory);
        if (!dir.exists() || !dir.isDirectory()) {
            boolean b = dir.mkdirs();
            if (!b) {
                log.error("创建目录失败！");
            }
        }
        File file = new File(new File(directory).getAbsolutePath() + File.separator + name);
        /*
         * 3. 数据写入文件
         */
        try {
            Files.copy(originFile.toPath(), file.toPath(), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            log.error(e.getMessage(), e);
            throw new AppException(ServerError.FILE_READ_WRITE_ERROR, e.getMessage());
        }

        if (!file.exists() || !file.isFile() || !(file.length() > 0) || !file.canRead()) {
            log.error("复制文件失败！");
            throw new AppException(ServerError.FILE_READ_WRITE_ERROR, file.toString());
        }

        /*
         * 4. 如果是图片文件，添加水印
         * tiny 版本暂未实现
         */
        String type = FileUtil.contentType(file);
        // if (option.getMark() && null != type) {if (type.startsWith("image/") || type.startsWith("video/")) {}}

        /*
         * 5. 整理 FileInfo
         */
        Long size = file.length();
        FileInfo fileInfo = new FileInfo();
        fileInfo.setId(id);
        fileInfo.setCode(code);
        fileInfo.setName(name);
        fileInfo.setOrigin(origin);
        fileInfo.setType(type);
        fileInfo.setSize(size);
        fileInfo.setPath(path);
        fileInfo.setValid(Boolean.TRUE);

        return fileInfo;
    }

    public void output(HttpServletResponse response, File file) {
        response.setContentType(FileUtil.contentType(file));
        String fileName = URLEncoder.encode(file.getName(), StandardCharsets.UTF_8);
        if (response.getHeader(HttpHeaders.CONTENT_DISPOSITION) == null) {
            response.addHeader(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"; filename*=utf-8' '" + fileName);
        }

        try (FileInputStream fis = new FileInputStream(file); BufferedInputStream bis = new BufferedInputStream(fis); OutputStream os = response.getOutputStream()) {
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = bis.read(buffer)) != -1) {
                os.write(buffer, 0, bytesRead);
            }
        } catch (Exception e) {
            log.error(e.getMessage(), e);
        }
    }

}
