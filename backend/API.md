# API Docs

当前后端同时提供两种文档方式：

- 交互式 Swagger: `GET /docs`
- 静态接口文档: 本文件

本文件基于当前已实现接口整理。

## Base

- Base URL: `http://127.0.0.1:8000`
- API Prefix: `/api/v1`
- Content-Type: `application/json`

鉴权接口之外，部分接口支持匿名访问；写操作通常需要：

```http
Authorization: Bearer <accessToken>
```

---

## Health

### GET `/health`

服务健康检查。

#### Response

```json
{
  "status": "ok"
}
```

---

## Auth

### POST `/api/v1/auth/register`

注册并直接返回 access token。

#### Request

```json
{
  "username": "testuser",
  "password": "testpassword123"
}
```

#### Notes

- `nickname` 当前改为可选
- 不传 `nickname` 时，后端默认使用 `username` 作为展示名
- 如果你想自定义展示名，也可以额外传：

```json
{
  "username": "testuser",
  "nickname": "Test User",
  "password": "testpassword123"
}
```

#### Response `201`

```json
{
  "accessToken": "jwt-token",
  "tokenType": "Bearer",
  "user": {
    "userId": 1,
    "userName": "Test User",
    "userAvatar": null
  }
}
```

#### Errors

- `409` 用户名已存在

### POST `/api/v1/auth/login`

登录并返回 access token。

#### Request

```json
{
  "username": "testuser",
  "password": "testpassword123"
}
```

#### Response `200`

```json
{
  "accessToken": "jwt-token",
  "tokenType": "Bearer",
  "user": {
    "userId": 1,
    "userName": "Test User",
    "userAvatar": null
  }
}
```

#### Errors

- `401` 用户名或密码错误

### GET `/api/v1/users/me`

获取当前登录用户。

#### Headers

```http
Authorization: Bearer <accessToken>
```

#### Response `200`

```json
{
  "userId": 1,
  "userName": "Test User",
  "userAvatar": null
}
```

---

## Posts

### GET `/api/v1/posts`

获取帖子流。

#### Query

- `feed`: `newest | hot | following`
- `cursor`: 可选，当前实现是 offset 字符串
- `limit`: 默认 `20`

#### Example

```bash
curl "http://127.0.0.1:8000/api/v1/posts?feed=newest&limit=20"
```

#### Response `200`

```json
{
  "items": [
    {
      "postId": 1,
      "userId": 1,
      "userName": "Test User",
      "userAvatar": null,
      "contentText": "My first post",
      "mediaList": [],
      "locationName": "Shenzhen",
      "publishTime": "2026-04-16T11:56:55.585835+08:00",
      "likeCount": 1,
      "commentCount": 2,
      "viewCount": 0,
      "isLiked": false,
      "isHot": false,
      "isFollowed": false,
      "isMine": false
    }
  ],
  "next_cursor": null,
  "limit": 20,
  "extra": {
    "feed": "newest"
  }
}
```

#### Notes

- 不带 token 查询时，`isLiked`、`isMine`、`isFollowed` 按匿名用户计算
- 带 token 查询时，这些字段会按当前用户计算

### GET `/api/v1/posts/{post_id}`

获取帖子详情。

#### Example

```bash
curl "http://127.0.0.1:8000/api/v1/posts/1"
```

### POST `/api/v1/posts`

创建帖子。

#### Headers

```http
Authorization: Bearer <accessToken>
Content-Type: application/json
```

#### Request

```json
{
  "contentText": "My first post from local backend",
  "locationName": "Shenzhen",
  "topicText": "Assembly",
  "mediaList": []
}
```

#### `mediaList` How To Pass

当前后端只支持图片，所以 `mediaType` 只有一个合法值：

- `image`

可以显式传：

```json
{
  "contentText": "Post with image",
  "mediaList": [
    {
      "mediaType": "image",
      "url": "https://example.com/post-image.jpg",
      "sortOrder": 1
    }
  ]
}
```

也可以省略 `mediaType`，后端会默认按 `image` 处理：

```json
{
  "contentText": "Post with image",
  "mediaList": [
    {
      "url": "https://example.com/post-image.jpg",
      "sortOrder": 1
    }
  ]
}
```

#### Rules

- `contentText` 和 `mediaList` 不能同时为空
- `mediaList` 最多 9 项
- `mediaList[*].mediaType` 当前只支持 `image`
- `mediaList[*].sortOrder` 取值范围 `1` 到 `9`

#### Response `201`

返回完整帖子对象。

### POST `/api/v1/posts/{post_id}/like`

点赞帖子。

#### Headers

```http
Authorization: Bearer <accessToken>
```

#### Response `200`

```json
{
  "postId": 1,
  "likeCount": 1
}
```

#### Errors

- `409` 重复点赞

### DELETE `/api/v1/posts/{post_id}/like`

取消点赞帖子。

#### Response `200`

```json
{
  "postId": 1
}
```

### POST `/api/v1/posts/{post_id}/view`

增加帖子浏览量。

#### Response `200`

```json
{
  "postId": 1,
  "viewCount": 1
}
```

---

## Comments

### GET `/api/v1/posts/{post_id}/comments`

获取评论树。

#### Query

- `cursor`: 可选
- `limit`: 默认 `30`

#### Response `200`

```json
{
  "items": [
    {
      "commentId": 1,
      "postId": 1,
      "parentCommentId": null,
      "rootCommentId": null,
      "replyToUserId": null,
      "replyToUserName": null,
      "userId": 1,
      "userName": "Test User",
      "userAvatar": null,
      "content": "First comment",
      "level": 1,
      "likeCount": 1,
      "isLiked": true,
      "createTime": "2026-04-16T11:59:14.096460+08:00",
      "replies": [
        {
          "commentId": 2,
          "postId": 1,
          "parentCommentId": 1,
          "rootCommentId": 1,
          "replyToUserId": 1,
          "replyToUserName": "Test User",
          "userId": 1,
          "userName": "Test User",
          "userAvatar": null,
          "content": "Reply comment",
          "level": 2,
          "likeCount": 0,
          "isLiked": false,
          "createTime": "2026-04-16T11:59:27.262180+08:00",
          "replies": []
        }
      ]
    }
  ],
  "next_cursor": null,
  "limit": 30,
  "extra": {
    "postId": 1
  }
}
```

### POST `/api/v1/posts/{post_id}/comments`

创建一级评论。

#### Headers

```http
Authorization: Bearer <accessToken>
Content-Type: application/json
```

#### Request

```json
{
  "content": "First comment"
}
```

#### Response `201`

返回完整评论对象。

### POST `/api/v1/comments/{comment_id}/reply`

回复评论。

#### Request

```json
{
  "content": "Reply comment",
  "replyToCommentId": 1
}
```

#### Response `201`

返回完整评论对象。

#### Notes

- 当前实现支持三级规则
- 回复评论后，帖子 `commentCount` 会同步增加

### POST `/api/v1/comments/{comment_id}/like`

点赞评论。

#### Response `200`

```json
{
  "commentId": 1,
  "likeCount": 1
}
```

### DELETE `/api/v1/comments/{comment_id}/like`

取消点赞评论。

#### Response `200`

```json
{
  "commentId": 1
}
```

### DELETE `/api/v1/comments/{comment_id}`

当前仍为占位接口，未实现删除评论。

#### Response

- `501 Not Implemented`

---

## Follows

### POST `/api/v1/users/{user_id}/follow`

当前为占位接口。

#### Response `200`

```json
{
  "userId": 2
}
```

### DELETE `/api/v1/users/{user_id}/follow`

当前为占位接口。

#### Response `200`

```json
{
  "userId": 2
}
```

---

## Uploads

### POST `/api/v1/uploads/images`

当前为占位上传接口，后续再接对象存储。

#### Headers

```http
Authorization: Bearer <accessToken>
Content-Type: multipart/form-data
```

#### Response `200`

```json
{
  "filename": "example.png",
  "message": "Upload placeholder. Store file in object storage later."
}
```

---

## Testing

当前已经有自动化测试覆盖核心链路。

### Run Tests

```bash
cd /Users/edy/Documents/service_demo/ai_setting/backend
TEST_DATABASE_URL=postgresql+psycopg://edy@localhost:5432/post_backend_test .venv312/bin/pytest
```

### Current Coverage

- 注册
- 登录
- `/users/me`
- 发帖
- 列表
- 详情
- 评论
- 回复
- 帖子点赞
- 评论点赞
- 取消点赞
