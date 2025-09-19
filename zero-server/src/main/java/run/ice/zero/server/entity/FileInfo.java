package run.ice.zero.server.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;
import run.ice.zero.server.model.Serializer;

import java.time.LocalDateTime;

/**
 * @author DaoDao
 */
@Getter
@Setter
@Entity
@DynamicInsert
@DynamicUpdate
@Table(schema = "zero_tiny", name = "file_info")
public class FileInfo implements Serializer {

    /**
     * 主键 ID
     */
    @Id
    @Column(name = "id")
    private String id;

    /**
     * code
     */
    @Column(name = "code")
    private String code;

    /**
     * 文件名
     */
    @Column(name = "name")
    private String name;

    /**
     * 源文件名
     */
    @Column(name = "origin")
    private String origin;

    /**
     * 文件类型
     */
    @Column(name = "type")
    private String type;

    /**
     * 文件大小
     */
    @Column(name = "size")
    private Long size;

    /**
     * 路径
     */
    @Column(name = "path")
    private String path;

    @Column(name = "create_time")
    private LocalDateTime createTime;

    @Column(name = "update_time")
    private LocalDateTime updateTime;

    /**
     * 是否有效
     */
    @Column(name = "valid")
    private Boolean valid;

    @Version
    @Column(name = "version")
    private Long version;

    @PrePersist
    protected void onCreate() {
        if (createTime == null) {
            createTime = LocalDateTime.now();
        }
        updateTime = LocalDateTime.now();
        if (valid == null) {
            valid = true;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updateTime = LocalDateTime.now();
    }

}
