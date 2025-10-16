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

### nfs

安装 nfs 服务

```shell
apt install nfs-kernel-server
```

创建 nfs 目录

```shell
sudo mkdir -p /data/nfs
sudo chown nobody:nogroup /data/nfs
sudo chmod 777 /data/nfs
```

配置 nfs 服务

```shell
sudo vim /etc/exports
```

写入配置

```text
/data/nfs 172.20.82.139(rw,sync,no_subtree_check,no_root_squash)
/data/nfs 172.20.82.140(rw,sync,no_subtree_check,no_root_squash)
/data/nfs 172.20.82.141(rw,sync,no_subtree_check,no_root_squash)
/data/nfs 172.20.82.142(rw,sync,no_subtree_check,no_root_squash)
```

重启 nfs 服务

```shell
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```

安装 nfs 客户端

```shell
sudo apt install nfs-common
```

---

### 初始化 Swarm 集群

如果 docker 没有启动 swarm 模式，则需要初始化 swarm 集群

```shell
docker swarm init
```

### 创建 overlay 网络

```shell
docker network create --driver overlay zero
```

### 创建数据卷

以 mysql 为例，创建数据卷。

如果是集群模式，建议使用 NFS 存储数据。

```shell
docker volume create --driver local --opt type=none --opt o=bind --opt device="${DATA_DIR}/mysql" "data-mysql"

## nfs
docker volume create --driver local --opt type=nfs --opt o=addr=192.168.1.1,rw --opt device=:/data/zero/mysql "zero_data-mysql"
```

### 部署服务

```shell
docker stack deploy -c compose.yaml zero
```
