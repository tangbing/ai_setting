# Backend

帖子模块后端，基于 `FastAPI + SQLAlchemy 2.x + Alembic + PostgreSQL`。

## 当前能力

已实现：
- 注册
- 登录
- 获取当前用户
- 帖子列表
- 帖子详情
- 发帖
- 帖子点赞 / 取消点赞
- 评论列表
- 发表评论
- 回复评论
- 评论点赞 / 取消点赞
- 本地图片上传

接口文档：
- Swagger: `http://127.0.0.1:8000/docs`
- 静态文档: [API.md](/Users/edy/Documents/service_demo/ai_setting/backend/API.md:1)

## 环境要求

- Python `3.12`
- PostgreSQL `16`

推荐虚拟环境：

```bash
backend/.venv312
```

## 安装

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
.venv312/bin/pip install -r requirements.txt
```

## 环境变量

复制模板：

```bash
cp .env.example .env
```

建议配置：

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

字段说明：
- `DATABASE_URL`: 开发数据库
- `JWT_SECRET_KEY`: JWT 签名密钥
- `UPLOAD_DIR`: 图片落盘目录
- `UPLOAD_MOUNT_PATH`: 静态访问路径

## 数据库初始化

创建开发库：

```bash
createdb post_backend
```

执行迁移：

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
.venv312/bin/alembic upgrade head
```

创建测试用户：

```bash
PYTHONPATH=. .venv312/bin/python scripts/create_test_user.py
```

## 启动服务

### 本机调试

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
PYTHONPATH=. .venv312/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
```

### 真机联调

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
PYTHONPATH=. .venv312/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

真机联调时，建议先验证：

```text
http://你的局域网IP:8000/health
```

## 上传说明

当前图片上传走本地文件落盘：
- 上传接口：`POST /api/v1/uploads/images`
- 存储目录：`backend/uploads/`
- 访问路径：`/media/uploads/<filename>`

当前限制：
- 仅支持 `jpeg/png/webp/gif`
- 暂不支持视频上传
- 暂不接对象存储

## 测试

测试库单独创建：

```bash
createdb post_backend_test
```

运行测试：

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
TEST_DATABASE_URL=postgresql+psycopg://edy@localhost:5432/post_backend_test .venv312/bin/pytest
```

注意：
- 不要把 `TEST_DATABASE_URL` 指向 `post_backend`
- 测试已经加了保护，开发库和测试库相同会直接失败

## 常见问题

### 1. `relation "users" does not exist`

通常是没跑迁移：

```bash
.venv312/bin/alembic upgrade head
```

如果之前测试误删了表，但 `alembic_version` 还在：

```bash
psql -d post_backend -c 'DROP TABLE IF EXISTS alembic_version;'
.venv312/bin/alembic upgrade head
```

### 2. `/docs` 里鉴权不生效

当前 Swagger 使用 Bearer token 方式。

先调：
- `POST /api/v1/auth/login`

再点 `Authorize`，填入 token。

### 3. 图片上传失败

检查：
- 后端是否启动
- 是否已登录
- 文件类型是否为图片
- `uploads/` 目录是否可写

## 主要文件

- 入口：[app/main.py](/Users/edy/Documents/service_demo/ai_setting/backend/app/main.py:1)
- 配置：[app/core/config.py](/Users/edy/Documents/service_demo/ai_setting/backend/app/core/config.py:1)
- 鉴权依赖：[app/api/deps.py](/Users/edy/Documents/service_demo/ai_setting/backend/app/api/deps.py:1)
- 帖子接口：[app/api/v1/posts.py](/Users/edy/Documents/service_demo/ai_setting/backend/app/api/v1/posts.py:1)
- 评论接口：[app/api/v1/comments.py](/Users/edy/Documents/service_demo/ai_setting/backend/app/api/v1/comments.py:1)
- 上传接口：[app/api/v1/uploads.py](/Users/edy/Documents/service_demo/ai_setting/backend/app/api/v1/uploads.py:1)
- Alembic 迁移：[alembic/versions/20260416_0001_init_post_backend.py](/Users/edy/Documents/service_demo/ai_setting/backend/alembic/versions/20260416_0001_init_post_backend.py:1)
