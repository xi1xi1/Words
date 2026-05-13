#!/usr/bin/env bash
# 生产一键拉起（compose.prod.yaml）。请先：secrets/mysql_root_password.txt、.env 中镜像与 JWT 等。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "缺少 .env，请复制 .env.example 为 .env 并填写。" >&2
  exit 1
fi

echo ">>> pull（需已 docker login ghcr.io 且镜像已推送）"
docker compose -f compose.prod.yaml --env-file .env pull

echo ">>> up -d"
docker compose -f compose.prod.yaml --env-file .env up -d

echo ">>> ps"
docker compose -f compose.prod.yaml ps

echo ">>> 完成。浏览器访问前端：见 .env 中 FRONTEND_PUBLISH_PORT（默认 80 → http://localhost/）"
