# docker

## build

```shell
cd zero-admin
docker build -t zero-admin .
```

## deploy

### 创建数据目录

以单机模式为例，创建数据目录 `${APP_DIR}` ， `${DATA_DIR}` ， `${LOGS_DIR}` 。

如果是集群模式，建议使用 NFS 存储数据。

```shell
mkdir -p ${APP_DIR} ${DATA_DIR} ${LOGS_DIR}
```

### 初始化 Swarm 集群

如果 docker 没有启动 swarm 模式，则需要初始化 swarm 集群

```shell
docker swarm init
```

### 创建 overlay 网络

```shell
docker network create -driver overlay zero
```

### 创建数据卷

以 mysql 为例，创建数据卷。

如果是集群模式，建议使用 NFS 存储数据。

```shell
docker volume create --driver local --opt type=none --opt o=bind --opt device="${DATA_DIR}/mysql" "data-mysql"

## nfs
docker volume create --driver local --opt type=nfs --opt o=addr=192.168.1.1,rw --opt device=:/data/zero/mysql "data-mysql"
```

### 部署服务

```shell
docker stack deploy -c compose.yaml zero
```
