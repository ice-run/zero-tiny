# zero-tiny

## 介绍

Zero-Tiny（零度极简版）：基于 Java 25+ 和 Spring Boot 4.x 的 Web 管理平台的快速开发模板框架

## 系统架构

项目分为前端和后端两个模块。

前端基于 vue-pure-admin 模板，使用 Vue3 + TypeScript + Element Plus + Pinia + Vite 开发。

后端基于 Spring Boot 4.x 开发。

支持基于 Docker 的容器技术方案。

## 构建部署

### 一键安装

```shell
curl -fsSLO https://gitee.com/ice-run/zero-tiny/raw/master/install.sh && chmod +x install.sh && ./install.sh
```

### 手动构建

```shell
./build.sh
```

### 更新部署

```shell
./deploy.sh
```

## 使用说明

浏览器访问

http://localhost

默认账号密码

admin | admin

## 参与贡献

1. Fork 本仓库
2. 新建 Feat_xxx 分支
3. 提交代码
4. 新建 Pull Request
