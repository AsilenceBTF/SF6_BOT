# 查看状态
sudo systemctl status docker
# 查看docker容器
docker ps -a
# 登录docker容器
docker exec -it id bash
# 重启docker容器
docker restart id
# 查看容器内网IP
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 容器名或ID
# 查看当前容器的详细网络信息
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.ID}}"
# 查看所有镜像
docker image ls
# 构建历史
docker history ID
# compose运行
docker-compose up -d