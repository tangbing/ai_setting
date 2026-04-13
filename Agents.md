# Agents.md

## 📌 项目说明

本项目基于 **Flutter 3.29.1 + Riverpod** 构建，用于快速开发中大型应用。


目标：

* 提供清晰的架构分层
* 规范状态管理使用方式
* 提升代码可维护性与扩展性
* 

---

## 🏗️ 架构设计

### 分层结构

```
lib/
 ├── core/           # 基础能力（网络/工具/常量）
 ├── models/         # 数据模型（json）
 ├── services/       # API 请求层
 ├── providers/      # Riverpod 状态管理
 ├── pages/          # 页面
 ├── widgets/        # 通用组件
```

---

## ⚙️ 状态管理（Riverpod）

### 基本原则

* UI 层：

    * 使用 `ref.watch()` 监听状态
* 事件触发：

    * 使用 `ref.read()` 调用方法
* 禁止：

    * 在 `build()` 中写复杂逻辑

---

### 命名规范

| 类型       | 命名            |
| -------- | ------------- |
| Provider | `xxxProvider` |
| Notifier | `xxxNotifier` |
| State    | `xxxState`    |

---

### 示例

```dart
final counterProvider =
    StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});
```

---

## 🧱 编码规范

### Widget

* 尽量使用 `const`
* 拆分小组件，避免 build 方法过长
* 避免嵌套过深

---

### 逻辑

* 页面不写业务逻辑
* 业务逻辑放入 Provider
* 网络请求放入 Service 层

---

## 🌐 网络层建议

推荐使用：

* dio（网络请求）
* 拦截器统一处理：

    * token
    * 错误码
    * 日志

---

## 🔄 状态分类建议

| 类型   | 用法            |
| ---- | ------------- |
| 简单状态 | StateProvider |
| 复杂状态 | StateNotifier |
| 异步数据 | AsyncNotifier |

---

## 🚀 扩展建议

推荐引入：

* 路由：go_router
* 本地存储：shared_preferences / hive
* 数据模型：freezed + json_serializable
* 日志：logger

---

## 📦 常用命令

```bash
flutter pub get
flutter run
flutter clean
```

---

## 🧠 开发建议

* 一个功能一个 Provider
* 避免 Provider 过大（拆分）
* 页面只负责 UI
* 保持数据流单向

---

## ⚠️ 常见坑

* ❌ 在 build 中调用 ref.read 修改状态
* ❌ Provider 依赖混乱
* ❌ UI 直接调用 API
* ❌ 未处理 loading / error 状态

---

## 🎯 目标

* 可维护
* 可扩展
* 可测试
* 清晰的数据流

---

## 📌 后续可扩展能力

* 登录态管理
* 全局 loading
* 分页列表
* 错误统一处理
* 多环境配置（dev / prod）

---

## 项目资源文档

* UI 设计图地址：https://nimbus-plugin-67471378.figma.site/
* 后端接口地址：无


---
