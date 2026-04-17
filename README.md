# ai_setting

Flutter 前端 + FastAPI 后端的帖子模块联调项目。

当前项目已经具备这些能力：
- Flutter 登录 / 注册
- 帖子列表、详情、评论、点赞
- 发纯文本帖子
- 本地图片上传后发帖
- FastAPI + PostgreSQL + Alembic
- 本地测试与真机局域网调试

## 目录

```text
lib/       Flutter 前端
backend/   FastAPI 后端
```

## 环境要求

前端：
- Flutter `3.29.1`
- Dart `3.7.x`

后端：
- Python `3.12`
- PostgreSQL `16`

本机开发时，推荐使用：
- `backend/.venv312`
- `Postgres.app`

## 前端配置

前端 API 地址统一在：
- [lib/core/network/api_config.dart](/Users/edy/Documents/service_demo/ai_setting/lib/core/network/api_config.dart:1)

当前默认地址：
```dart
http://192.168.20.131:8000
```

这个地址适合当前局域网真机调试。如果你换了 Wi-Fi，推荐不要直接改代码，而是用启动参数覆盖：

```bash
flutter run --dart-define=API_ORIGIN=http://你的局域网IP:8000
```

示例：
```bash
flutter run --dart-define=API_ORIGIN=http://192.168.20.131:8000
```

## 后端配置

后端环境变量模板：
- [backend/.env.example](/Users/edy/Documents/service_demo/ai_setting/backend/.env.example:1)

首次使用：

```bash
cd backend
cp .env.example .env
```

本地推荐配置：

```env
APP_NAME=Post Backend
APP_ENV=development
APP_DEBUG=true
API_V1_PREFIX=/api/v1
DATABASE_URL=postgresql+psycopg://edy@localhost:5432/post_backend
JWT_SECRET_KEY=change-me
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080
UPLOAD_DIR=uploads
UPLOAD_MOUNT_PATH=/media/uploads
```

## 数据库准备

确保 PostgreSQL 已启动，然后创建开发库：

```bash
createdb post_backend
```

执行迁移：

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
.venv312/bin/alembic upgrade head
```

如需测试用户：

```bash
PYTHONPATH=. .venv312/bin/python scripts/create_test_user.py
```

## 安装与启动

### 1. 安装后端依赖

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
.venv312/bin/pip install -r requirements.txt
```

### 2. 启动后端

本机浏览器调试可用：

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
PYTHONPATH=. .venv312/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
```

真机联调必须改成监听局域网：

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
PYTHONPATH=. .venv312/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 3. 启动前端

```bash
cd /Users/edy/Documents/service_demo/ai_setting
flutter pub get
flutter run --dart-define=API_ORIGIN=http://192.168.20.131:8000
```

## 真机调试说明

真机访问后端时，必须满足：
- 手机和 Mac 在同一个 Wi-Fi
- 后端使用 `0.0.0.0:8000` 启动
- 手机浏览器能打开 `http://192.168.20.131:8000/health`
- macOS 防火墙如弹窗，允许 Python / uvicorn 入站

建议先用手机浏览器访问：

```text
http://192.168.20.131:8000/health
```

返回：

```json
{"status":"ok"}
```

说明网络已经通了。

## 已接通的业务链路

前端已接后端接口：
- 登录
- 注册
- 获取当前用户
- 帖子列表
- 帖子详情
- 帖子点赞 / 取消点赞
- 评论列表
- 发表评论
- 回复评论
- 图片上传
- 图片发帖

当前仍有限制：
- 视频上传未接通
- 评论点赞能力后端已支持，前端 UI 还未暴露入口

## 常用验证地址

后端健康检查：
- `http://127.0.0.1:8000/health`
- `http://192.168.20.131:8000/health`

Swagger：
- `http://127.0.0.1:8000/docs`
- `http://192.168.20.131:8000/docs`

静态 API 文档：
- [backend/API.md](/Users/edy/Documents/service_demo/ai_setting/backend/API.md:1)

## 测试

Flutter：

```bash
cd /Users/edy/Documents/service_demo/ai_setting
flutter test
```

后端测试数据库建议单独创建：

```bash
createdb post_backend_test
```

运行后端测试：

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
TEST_DATABASE_URL=postgresql+psycopg://edy@localhost:5432/post_backend_test .venv312/bin/pytest
```

不要把测试库指向开发库 `post_backend`。

## 常见问题

### 1. 注册时报 `relation "users" does not exist`

说明数据库表没建好，先执行：

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
.venv312/bin/alembic upgrade head
```

### 2. 真机请求失败

先检查：
- 后端是否用 `0.0.0.0` 启动
- 手机和 Mac 是否同网
- `API_ORIGIN` 是否是当前 Mac 的局域网 IP

### 3. 图片发帖失败

先检查：
- 后端是否在运行
- `/api/v1/uploads/images` 是否可访问
- 是否为图片文件

## 补充文档

后端专项说明见：
- [backend/README.md](/Users/edy/Documents/service_demo/ai_setting/backend/README.md:1)

产品与技术文档：
- [帖子需求.md](/Users/edy/Documents/service_demo/ai_setting/帖子需求.md:1)
- [帖子后端.md](/Users/edy/Documents/service_demo/ai_setting/帖子后端.md:1)
