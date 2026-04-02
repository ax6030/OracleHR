# ─── Stage 1: Build ───────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# 先複製 package.json 再 install，利用 Docker layer cache
# 只要 package.json 沒變，install 這層就不會重跑
COPY package.json ./
RUN npm install

# 複製其餘原始碼並建置
COPY . .
RUN npm run build
# build 產出在 /app/dist

# ─── Stage 2: Serve ───────────────────────────────────────
FROM nginx:alpine AS runtime

# 複製自訂 nginx 設定（支援 Vue Router history mode）
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 複製 Vite build 產出
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
