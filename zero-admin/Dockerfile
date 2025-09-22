FROM registry.cn-beijing.aliyuncs.com/daodao-bot/node:24 AS builder
WORKDIR /build
COPY . .
ENV NODE_OPTIONS="--max-old-space-size=8192"
RUN npm install -g pnpm
RUN pnpm config set registry https://registry.npmmirror.com
RUN pnpm install
RUN pnpm run build

FROM registry.cn-beijing.aliyuncs.com/daodao-bot/nginx:1.29.0
VOLUME /tmp
COPY --from=builder /build/dist /usr/share/nginx/html
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]
