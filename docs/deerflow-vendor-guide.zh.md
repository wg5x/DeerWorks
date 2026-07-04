# DeerFlow Vendor 导览

这份文档面向第一次接手 DeerFlow 代码库的开发者，帮助你快速判断项目是什么、怎么启动、代码入口在哪里，以及改不同模块时应该先读哪些文件。

## 项目定位

DeerFlow 是一个基于 LangGraph 的全栈 AI agent 平台。它的核心不是单个聊天机器人，而是一个可扩展的 super-agent harness：后端负责 agent 编排、工具调用、沙箱执行、长期记忆、子 agent 委派、MCP 与 skills 集成；前端提供线程化聊天、流式响应、文件与 artifact 预览、设置和 agent 管理界面。

当前仓库是 DeerFlow 2.x。官方 README 提到 2.x 是一次重写，和 1.x 分支不共享代码。

## 服务拓扑

本地开发或 Docker 启动时，项目由几个协作服务组成：

| 服务 | 默认端口 | 作用 |
| --- | --- | --- |
| Nginx | `2026` | 统一入口，浏览器通常访问这里 |
| Gateway API | `8001` | FastAPI REST API，同时内嵌 LangGraph 兼容运行时 |
| Frontend | `3000` | Next.js Web 界面 |
| Provisioner | `8002` | 可选服务，仅在特定 sandbox/provisioner 配置下启动 |

标准入口是 Nginx。它会把前端请求和后端 API 统一到同一个本地地址下，并将 `/api/langgraph/*` 转发到 Gateway 的 LangGraph runtime。

## 目录地图

```text
vendor/deer-flow/
├── Makefile                        # 根命令：安装、配置、启动、停止、Docker
├── README.md                       # 官方英文 README
├── README_zh.md                    # 官方中文 README
├── AGENTS.md                       # 仓库级开发导览和约定
├── config.example.yaml             # 主配置模板，复制为 config.yaml
├── extensions_config.example.json  # MCP servers 与 skills 配置模板
├── backend/                        # Python 后端
│   ├── AGENTS.md                   # 后端架构和开发约定
│   ├── Makefile                    # 后端单模块命令
│   ├── app/                        # Gateway API 与 IM channel 应用层
│   ├── packages/harness/           # deerflow-harness 核心 agent 框架
│   └── tests/                      # 后端测试
├── frontend/                       # Next.js 前端
│   ├── AGENTS.md                   # 前端架构和开发约定
│   ├── package.json                # 前端脚本和依赖
│   ├── src/app/                    # Next.js App Router
│   ├── src/components/             # UI 与工作区组件
│   ├── src/core/                   # 前端业务逻辑
│   └── tests/                      # 前端单测与 E2E
├── docker/                         # docker-compose、nginx、provisioner
├── skills/                         # 内置与自定义 agent skills
├── contracts/                      # 跨组件 JSON contract
├── scripts/                        # 安装、诊断、启动、配置脚本
└── docs/                           # 补充设计文档、计划和项目说明
```

## 快速启动

第一次启动建议从项目根目录执行：

```bash
cd /Users/wgxxx/Github/DeerWorks/vendor/deer-flow
make setup
make doctor
make dev
```

常用根命令：

```bash
make setup          # 交互式生成本地配置
make doctor         # 检查配置和运行环境
make config         # 从模板生成本地 config.yaml / extensions_config.json
make install        # 安装前后端依赖和 pre-commit hooks
make dev            # 本地开发启动全栈服务
make start          # 本地生产模式启动
make stop           # 停止本地服务
make docker-start   # Docker 开发模式启动
make docker-stop    # 停止 Docker 开发服务
make up             # Docker 生产模式启动
make down           # 停止 Docker 生产服务
```

如果只改后端：

```bash
cd backend
make dev
make test
make lint
make format
```

如果只改前端：

```bash
cd frontend
pnpm dev
pnpm check
pnpm test
pnpm test:e2e
```

## 配置文件

运行时配置位于仓库根目录：

| 文件 | 来源 | 作用 |
| --- | --- | --- |
| `config.yaml` | 从 `config.example.yaml` 生成 | 模型、数据库、sandbox、memory、tracing、工具等主配置 |
| `extensions_config.json` | 从 `extensions_config.example.json` 生成 | MCP servers、skills 等扩展配置 |
| `.env` | setup wizard 或手动创建 | API key 和环境变量 |

真实配置文件通常被 git 忽略。修改 `config.yaml` 后，很多运行时字段会在下一次请求或下一次 agent run 中被重新读取；数据库、sandbox、channel 等基础设施字段通常需要重启服务。

## 后端导览

后端分成两个层次：

| 层 | 路径 | import 前缀 | 职责 |
| --- | --- | --- | --- |
| Harness | `backend/packages/harness/deerflow/` | `deerflow.*` | 可复用 agent 框架：LangGraph agent、tools、sandbox、MCP、skills、memory、模型工厂、runtime |
| App | `backend/app/` | `app.*` | 应用层：FastAPI Gateway、认证、REST routers、IM channels |

依赖方向是 App 可以依赖 Harness，但 Harness 不能依赖 App。这个边界由测试保护。

### 关键入口

| 文件或目录 | 用途 |
| --- | --- |
| `backend/app/gateway/app.py` | FastAPI 应用入口和 lifespan 初始化 |
| `backend/app/gateway/routers/` | Gateway REST API 路由 |
| `backend/packages/harness/deerflow/agents/lead_agent/agent.py` | lead agent 构造入口 |
| `backend/packages/harness/deerflow/agents/thread_state.py` | LangGraph agent 状态结构 |
| `backend/packages/harness/deerflow/agents/middlewares/` | agent 中间件链 |
| `backend/packages/harness/deerflow/runtime/` | Gateway 内嵌 LangGraph runtime 支撑 |
| `backend/packages/harness/deerflow/sandbox/` | 沙箱接口、生命周期和文件/命令工具 |
| `backend/packages/harness/deerflow/subagents/` | 子 agent 注册、执行和状态事件 |
| `backend/packages/harness/deerflow/mcp/` | MCP client、工具加载和缓存 |
| `backend/packages/harness/deerflow/skills/` | skill 发现、解析、权限和安装 |
| `backend/packages/harness/deerflow/models/` | 模型工厂和 provider 适配 |
| `backend/app/channels/` | Slack、Telegram、Feishu、DingTalk、Discord 等 IM 集成 |

### 后端主流程

简化后的后端执行路径：

```text
Frontend / IM channel
  -> Gateway API
  -> LangGraph-compatible runtime
  -> RunManager / StreamBridge
  -> lead agent
  -> middleware chain
  -> tools / sandbox / MCP / subagents / memory
  -> streamed events
  -> Gateway
  -> Frontend
```

agent 中间件链比较长，承担输入清理、上传文件注入、sandbox 生命周期、工具错误处理、skills 激活、上下文压缩、token 统计、标题生成、memory、图片输入、subagent 限制、循环检测、预算控制等工作。修改 agent 行为时，建议先读 `backend/AGENTS.md` 的 Middleware Chain 章节。

## 前端导览

前端是 Next.js 16 + React 19 + TypeScript + Tailwind CSS 4。它通过 LangGraph SDK 与后端 runtime 交互，使用 TanStack Query 管理服务端状态。

### 关键入口

| 路径 | 用途 |
| --- | --- |
| `frontend/src/app/` | Next.js App Router 页面和 API route handlers |
| `frontend/src/app/workspace/` | 工作区主页面 |
| `frontend/src/app/workspace/chats/[thread_id]/page.tsx` | 单个聊天线程页面 |
| `frontend/src/app/workspace/agents/` | 自定义 agent 页面 |
| `frontend/src/components/workspace/` | 聊天、输入框、侧边栏、artifact、goal、设置等组件 |
| `frontend/src/core/threads/` | 线程创建、提交、流式响应和状态更新 |
| `frontend/src/core/api/` | LangGraph API client 和 fetcher |
| `frontend/src/core/tasks/` | subagent task 卡片和步骤流 |
| `frontend/src/core/artifacts/` | artifact 加载、预览和工具函数 |
| `frontend/src/core/skills/` | skills API 与 hooks |
| `frontend/src/core/models/` | 模型列表 API 与 hooks |
| `frontend/src/core/settings/` | 本地设置状态 |
| `frontend/src/core/i18n/` | 多语言支持 |

### 前端数据流

```text
用户输入
  -> workspace input box
  -> core/threads hooks
  -> LangGraph SDK stream
  -> 流事件更新 messages / artifacts / todos / goal / tasks
  -> React components 渲染工作区
```

`/goal` 是前端输入框里的内置命令，不是普通 skill。它会调用 Gateway 的 thread goal API，并根据命令内容决定是否同时提交一次 agent 任务。

## Skills、MCP 和 Sandbox

DeerFlow 的可扩展性主要来自三个系统：

| 系统 | 路径 | 说明 |
| --- | --- | --- |
| Skills | `skills/public/`、`skills/custom/`、`backend/packages/harness/deerflow/skills/` | 用 Markdown 描述 agent 能力、工作流和脚本资源 |
| MCP | `backend/packages/harness/deerflow/mcp/` | 接入外部 MCP server，并把能力暴露为工具 |
| Sandbox | `backend/packages/harness/deerflow/sandbox/` | 为 agent 提供隔离的命令执行和文件操作环境 |

公共 skills 会提交到仓库；自定义 skills 通常放在 `skills/custom/`，不进入 git。

## 测试和质量检查

后端：

```bash
cd backend
make test
make test-blocking-io
make lint
```

前端：

```bash
cd frontend
pnpm check
pnpm test
pnpm test:e2e
```

根目录也提供一些跨项目检查：

```bash
make check
make doctor
make detect-blocking-io
make support-bundle
```

开发约定里强调：后端功能和 bugfix 通常要配测试；前端改动要跑 `pnpm check`，必要时补单测或 E2E。

## 修改代码时先读哪里

| 你要做的事 | 建议先读 |
| --- | --- |
| 调整启动、安装、配置流程 | `Makefile`、`scripts/`、`Install.md` |
| 改 Gateway API | `backend/app/gateway/app.py`、`backend/app/gateway/routers/`、`backend/AGENTS.md` |
| 改 agent 行为 | `backend/packages/harness/deerflow/agents/lead_agent/`、`agents/middlewares/`、`backend/AGENTS.md` |
| 改工具调用或 sandbox 文件操作 | `backend/packages/harness/deerflow/sandbox/`、`tools/` |
| 改 skills 逻辑 | `skills/public/`、`backend/packages/harness/deerflow/skills/` |
| 改 MCP 集成 | `backend/packages/harness/deerflow/mcp/` |
| 改子 agent | `backend/packages/harness/deerflow/subagents/`、`contracts/subagent_status_contract.json` |
| 改聊天 UI | `frontend/src/app/workspace/chats/`、`frontend/src/components/workspace/` |
| 改流式响应状态 | `frontend/src/core/threads/` |
| 改 artifact 预览 | `frontend/src/core/artifacts/`、`frontend/src/components/workspace/` |
| 改前端 API hooks | `frontend/src/core/*/api.ts`、`frontend/src/core/*/hooks.ts` |
| 改国际化文案 | `frontend/src/core/i18n/`、`frontend/src/content/` |

## 接手建议

1. 先读根目录 `AGENTS.md`，理解 monorepo 边界和命令体系。
2. 如果改后端，再读 `backend/AGENTS.md`；如果改前端，再读 `frontend/AGENTS.md`。
3. 先用 `make doctor` 确认本地环境，再启动 `make dev`。
4. 改 agent 行为时，不要只看 lead agent 文件；中间件链、ThreadState reducer、runtime streaming 都可能影响最终行为。
5. 改前端聊天行为时，重点追 `core/threads` 的 stream 更新逻辑，再看页面组件。
6. 代码变更时同步更新相关文档，尤其是 README 和对应模块的 `AGENTS.md`。
