SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS `zero_tiny` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

CREATE USER IF NOT EXISTS 'zero'@'%' IDENTIFIED BY 'zero';

GRANT ALL PRIVILEGES ON `zero_tiny`.* TO 'zero'@'%';

FLUSH PRIVILEGES;

USE `zero_tiny`;

CREATE TABLE IF NOT EXISTS `zero_tiny`.`user`
(
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'id',
    `username`    VARCHAR(32)     NOT NULL COMMENT '用户名',
    `password`    VARCHAR(128)    NOT NULL COMMENT '密码',
    `nickname`    VARCHAR(32)              DEFAULT NULL COMMENT '昵称',
    `avatar`      VARCHAR(128)             DEFAULT NULL COMMENT '头像',
    `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `valid`       BOOLEAN         NOT NULL DEFAULT TRUE COMMENT '是否有效：FALSE 无效，TRUE 有效',
    `version`     BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '版本号',
    PRIMARY KEY (`id`),
    UNIQUE KEY `username` (`username`),
    KEY `nickname` (`nickname`),
    KEY `create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_bin COMMENT ='用户';

-- password: admin
INSERT INTO `zero_tiny`.`user` (`username`, `password`)
VALUES ('admin', '{bcrypt}$2a$10$oH3U9NjVVtNIWbofevCqXOUk6VynxgMkdLE89UQxI1wxPQLVNJNA.');

CREATE TABLE IF NOT EXISTS `zero_tiny`.`file_info`
(
    `id`          VARCHAR(32)     NOT NULL COMMENT 'id',
    `code`        VARCHAR(32)     NOT NULL COMMENT 'code',
    `name`        VARCHAR(64)     NOT NULL COMMENT '文件名',
    `origin`      VARCHAR(128)    NOT NULL COMMENT '源文件名',
    `type`        VARCHAR(128)    NOT NULL COMMENT '文件类型',
    `size`        BIGINT UNSIGNED NOT NULL COMMENT '文件大小',
    `path`        VARCHAR(16)     NOT NULL COMMENT '文件路径',
    `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    `valid`       BOOLEAN         NOT NULL DEFAULT TRUE COMMENT '是否有效：TRUE 有效，FALSE 无效',
    `version`     BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '版本号',
    PRIMARY KEY (`id`),
    UNIQUE KEY `code` (`code`),
    KEY `create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_bin
    COMMENT ='文件信息';
