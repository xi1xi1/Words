# 基础镜像拉取慢：① Docker Desktop 配 registry-mirrors ② 试换下行镜像源（与 CI Flutter 版本对齐）
# FROM ghcr.io/cirruslabs/flutter:3.35.7 AS builder
FROM ghcr.io/cirruslabs/flutter:3.35.7 AS builder
WORKDIR /app

# 国内构建时加速 Flutter SDK / Pub 包下载（不改变代码逻辑）
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
    PUB_HOSTED_URL=https://pub.flutter-io.cn

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null || exit 1
