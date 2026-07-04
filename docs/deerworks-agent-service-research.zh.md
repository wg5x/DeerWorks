# DeerWorks Agent 集合服务调研

这份文档调研 DeerWorks 是否可以基于 DeerFlow 做成一个 Agent 集合服务。这里的“Agent 集合服务”指：平台集中创建、配置和运行多个 Agent，并把这些 Agent 暴露成 API。上层应用通过调用 Agent API 来组合出面向不同客户和场景的服务。

本仓库不内置 RAG，也不直接承载业务数据库。RAG、通用数据库、业务系统和外部工具都应通过 MCP 或普通 API 作为外部能力接入 Agent。

## 目标能力

DeerWorks 需要支撑四类能力：

| 能力 | 说明 | DeerFlow 现状 |
| --- | --- | --- |
| 平台能力 | 能创建多个 Agent，并维护 Agent 的说明、模型、工具、技能和行为约束 | 支持 custom agents |
| 访问能力 | Agent 能访问 tools、通用数据库 MCP、RAG MCP 和其他外部能力 | 支持 MCP servers 和内置工具 |
| 接口能力 | Agent 可以作为 API 被上层应用调用 | 支持 runs/thread runs API |
| 应用构建 | 多个 Agent API 可以被应用组合，形成客户服务、行业助手、业务自动化等应用 | 需要 DeerWorks 做更清晰的 API 包装和治理 |

## 项目边界

DeerWorks 应该聚焦在 Agent 服务，不把边界扩张成全套应用平台。

DeerWorks 负责：

- Agent 注册、配置、分组和版本记录。
- Agent API 的暴露、调用、流式输出和同步等待。
- Agent 与 MCP tools 的绑定策略。
- Agent 调用日志、审计、用量统计和错误追踪。
- 对 DeerFlow runtime 的运行配置、部署和升级管理。

DeerWorks 不负责：

- 不实现 RAG 存储和向量检索。
- 不维护上层应用的 PostgreSQL、Redis 或其他业务数据库。
- 不承载具体客户应用的业务页面和业务流程。
- 不把 DeerFlow vendor 源码混入顶层项目历史。

外部系统通过 MCP 或普通 API 进入 Agent：

```text
Application
  -> DeerWorks Agent API
  -> DeerFlow Agent
  -> MCP Tool
  -> RAG / PostgreSQL / Redis / CRM / File Storage / Search / Other Tools
```

## DeerFlow 支撑情况

### 多 Agent

DeerFlow 已有 custom agents API。每个 Agent 包含：

- `name`
- `description`
- `model`
- `tool_groups`
- `skills`
- `SOUL.md`

这些字段对应 Agent 的身份、行为、模型选择、工具集合和 skill 白名单。

需要注意的是，DeerFlow 的 custom agent 不是多个完全独立的 graph。它的实现方式是：

```text
same lead_agent graph
  + assistant_id
  -> agent_name
  -> load custom agent config / SOUL.md
```

这非常适合 DeerWorks 第一阶段。多个 Agent 可以先作为同一个 runtime 下的不同配置运行，而不需要维护多套 graph。

### Agent API

DeerFlow 的 run API 支持 `assistant_id`。当 `assistant_id` 不是默认的 `lead_agent` 时，Gateway 会把它转换成 `agent_name` 并注入运行配置。`make_lead_agent` 再读取 `agent_name`，加载对应 Agent 的配置和 SOUL。

因此 DeerWorks 可以把自己的 `agent_id` 映射到 DeerFlow 的 `assistant_id`：

```text
DeerWorks agent_id
  -> DeerFlow assistant_id
  -> runtime context agent_name
  -> custom agent config
```

### MCP 工具

DeerFlow 支持通过 `extensions_config.json` 或 `mcp_config.json` 配置 MCP servers。MCP server 支持：

- `stdio`
- `sse`
- `http`
- `headers`
- `oauth`
- `env`
- `tool_call_timeout`

因此 RAG、通用数据库和外部工具都可以作为 MCP server 接入。

示例方向：

```text
rag-search MCP
postgres MCP
redis MCP
crm MCP
file-storage MCP
search MCP
```

### 应用组合

上层应用不需要直接理解 DeerFlow 的内部 thread、checkpoint、middleware 和 tool loading 细节。DeerWorks 可以提供更稳定、更业务化的 Agent API：

```text
Application A -> customer-support-agent
Application B -> document-qa-agent + workflow-agent
Application C -> research-agent + data-analysis-agent
```

不同应用可以组合多个 Agent API 来构建自己的服务。Agent 内部再通过 MCP 访问 RAG、数据库或其他工具。

## 当前约束

### MCP 是全局加载

DeerFlow 当前会从全局 `extensions_config.json` 加载 enabled MCP tools。custom agent 的 `tool_groups` 主要影响配置中的内置工具分组，MCP tools 默认是全局进入工具集合。

如果需要做到“每个 Agent 只能看到某些 MCP tools”，需要额外设计：

- 用 skill 的 `allowed-tools` 限制 Agent 可用工具。
- 或在 DeerWorks 层维护 agent -> tool allowlist，再注入到 DeerFlow 配置或包装层。
- 或后续修改 DeerFlow tool loading，让 MCP server / MCP tool 支持 agent-scoped filtering。

第一阶段可以先采用 skill allowed-tools 或命名约定，不急着改 vendor 源码。

### Agent 管理 API 默认关闭

DeerFlow 的 custom-agent 管理 API 默认关闭，需要 `agents_api.enabled=true`。配置里也提示：只有在 Gateway 位于可信认证管理边界后才应开启。

DeerWorks 如果要对外提供 Agent 创建能力，应该自己做一层管理 API，并明确权限边界，再决定是否调用 DeerFlow 原生 `/api/agents`。

### API 形态偏底层

DeerFlow 的 `/api/runs/*` 和 `/api/threads/*/runs/*` 更接近 LangGraph Platform 兼容层。DeerWorks 面向应用时，最好提供更稳定的业务 API，并把 DeerFlow 的细节包在内部。

## 可行性结论

基于现有 DeerFlow，DeerWorks 做 Agent 集合服务是可行的。

推荐的第一阶段实现方式：

1. DeerFlow 保持为 Agent runtime 基线。
2. DeerWorks 定义自己的 Agent registry 和 API 层。
3. 每个 DeerWorks Agent 映射到 DeerFlow custom agent / assistant_id。
4. RAG 和外部工具统一通过 MCP 接入。
5. Agent 级 tool 权限先通过配置和 skill allowed-tools 管控。
6. 后续如果需要更强隔离，再考虑扩展 DeerFlow 的 MCP filtering 或引入独立 agent runtime。

这个路径能最大化复用 DeerFlow 当前能力，也能保持 DeerWorks 顶层项目的边界清楚。
