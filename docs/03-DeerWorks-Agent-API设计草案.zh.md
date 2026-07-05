# DeerWorks Agent API 设计草案

这份文档描述 DeerWorks 面向上层应用暴露 Agent API 的第一版设计。它不是 DeerFlow 原生 API 的替代实现，而是一层更贴近应用开发的包装：上层应用调用 DeerWorks API，DeerWorks 再把请求映射到 DeerFlow 的 custom agent 和 run API。

## 设计目标

- 对上层应用隐藏 DeerFlow 内部的 LangGraph run、thread、checkpoint 细节。
- 用稳定的 `agent_id` 暴露多个 Agent。
- 支持同步调用和流式调用。
- 支持可选上下文保留，即同一个 `conversation_id` 多次调用同一个 Agent。
- 支持记录调用来源、应用、客户、场景和业务元数据。
- 为后续鉴权、审计、限流、计费和 observability 留出位置。

## 对外服务形态

DeerWorks 暴露的是 Agent API SaaS，而不是替代所有应用后端的通用 SaaS 框架。

上层业务可以有两种形态：

1. Agent 驱动型 SaaS：应用本身较薄，核心能力主要由 DeerWorks Agent API 提供，例如客服问答、合同审查、报告生成、文档分析。
2. 传统应用 SaaS + Agent 增强：应用拥有自己的 UI、后端和业务数据库，只在需要智能能力时调用 DeerWorks Agent API，例如 CRM、ERP、工单、项目管理或行业业务系统。

因此 DeerWorks API 的职责是稳定地暴露 Agent 能力，而不是接管应用自己的数据库访问和业务流程。应用自己的数据库可以由应用后端直接访问；Agent 需要访问数据库时，则应通过 MCP tool 受控访问。

## 核心对象

### Agent

Agent 是 DeerWorks 对外暴露的能力单元。

```text
Agent
├── agent_id
├── name
├── description
├── deerflow_assistant_id
├── model_policy
├── mcp_tool_policy
├── skills
├── enabled
└── metadata
```

第一阶段可以直接让 `agent_id` 等于 DeerFlow custom agent 的 `assistant_id`。后续如果 DeerWorks 需要维护更复杂的注册表，可以增加映射层。

### Run

Run 是一次 Agent 调用。

```text
Run
├── run_id
├── agent_id
├── conversation_id
├── input
├── output
├── status
├── metadata
├── created_at
└── updated_at
```

DeerFlow 内部已经有 run store 和 thread metadata。DeerWorks 包装层可以先复用 DeerFlow 的 run id 和 thread id。

### Conversation

Conversation 对应 DeerFlow thread。它用于多轮上下文保留。

```text
conversation_id -> DeerFlow thread_id
```

如果调用方不传 `conversation_id`，DeerWorks 可以走 stateless run，由 DeerFlow 自动创建临时 thread。

## API 草案

### List Agents

```http
GET /api/agents
```

返回 DeerWorks 可用的 Agent 列表。

响应示例：

```json
{
  "agents": [
    {
      "agent_id": "customer-support",
      "name": "Customer Support",
      "description": "面向客服场景的 Agent",
      "enabled": true
    }
  ]
}
```

映射方式：

- 第一阶段可读取 DeerFlow `/api/agents` 或本地 Agent registry。
- 如果 DeerFlow `agents_api.enabled=false`，则更适合由 DeerWorks 自己维护 registry 文件。

### Get Agent

```http
GET /api/agents/{agent_id}
```

返回单个 Agent 的公开信息和能力说明。

响应示例：

```json
{
  "agent_id": "document-qa",
  "name": "Document QA",
  "description": "通过 RAG MCP 查询外部知识库",
  "capabilities": ["rag-search", "citation", "summarization"],
  "enabled": true
}
```

### Run Agent And Wait

```http
POST /api/agents/{agent_id}/runs
```

同步等待 Agent 完成，适合短任务和普通应用接口。

请求示例：

```json
{
  "input": {
    "messages": [
      {
        "role": "user",
        "content": "帮我查一下这个产品的售后政策"
      }
    ]
  },
  "conversation_id": "optional-conversation-id",
  "metadata": {
    "app_id": "support-portal",
    "customer_id": "acme",
    "scenario": "after-sales"
  }
}
```

内部映射到 DeerFlow：

```text
POST /api/runs/wait
assistant_id = agent_id
config.configurable.thread_id = conversation_id if provided
input = request.input
metadata = request.metadata
```

### Run Agent Stream

```http
POST /api/agents/{agent_id}/runs/stream
```

返回 SSE 流，适合聊天 UI、长任务和需要实时反馈的应用。

内部映射到 DeerFlow：

```text
POST /api/runs/stream
assistant_id = agent_id
stream_mode = ["values"] or caller-selected modes
```

### Get Run

```http
GET /api/runs/{run_id}
```

查询一次调用的状态、摘要和元数据。

第一阶段可以直接代理 DeerFlow run store 的查询能力；后续可以在 DeerWorks 自己的审计表中补充更多业务字段。

## 调用链路

### 简单同步任务

```text
Application
  -> POST /api/agents/{agent_id}/runs
  -> DeerWorks maps agent_id to assistant_id
  -> DeerFlow /api/runs/wait
  -> Agent executes
  -> optional MCP tool calls
  -> final response
```

### 流式任务

```text
Application
  -> POST /api/agents/{agent_id}/runs/stream
  -> DeerWorks maps agent_id to assistant_id
  -> DeerFlow /api/runs/stream
  -> SSE events
  -> Application UI
```

### 多轮任务

```text
Application conversation_id
  -> DeerWorks conversation_id
  -> DeerFlow thread_id
  -> checkpoint / history
```

## 权限和治理

第一阶段至少需要保留这些治理点：

- API key 或应用身份。
- app_id 到 agent_id 的 allowlist。
- agent_id 到 MCP tools 的 allowlist。
- run metadata 记录调用来源。
- 限流和最大递归步数。
- 错误和超时处理。
- 日志和审计。

其中 `app_id -> agent_id` 和 `agent_id -> MCP tools` 是 DeerWorks 自己应该明确维护的边界。不要完全依赖 Agent prompt 自律。

## 与 DeerFlow API 的关系

DeerWorks API 是应用开发入口；DeerFlow API 是 runtime 内部接口。

```text
Application
  -> DeerWorks Agent API
  -> DeerFlow Gateway API
  -> lead_agent runtime
```

这样做的好处：

- 上层应用不会被 DeerFlow API 变动影响。
- DeerWorks 可以加鉴权、审计、限流、灰度和 agent registry。
- 未来如果 Agent runtime 从 DeerFlow 扩展到其他实现，应用 API 不必重写。

## 第一阶段建议

第一阶段可以先做很薄的一层：

1. 定义 `agents.yaml` 或数据库表，维护 Agent registry。
2. 实现 `/api/agents` 和 `/api/agents/{agent_id}`。
3. 实现 `/api/agents/{agent_id}/runs`，内部调用 DeerFlow `/api/runs/wait`。
4. 实现 `/api/agents/{agent_id}/runs/stream`，内部调用 DeerFlow `/api/runs/stream`。
5. 把 `conversation_id` 映射到 DeerFlow `thread_id`。
6. 把 `metadata` 透传到 DeerFlow run metadata，并在 DeerWorks 侧记录审计日志。

这一阶段不需要改 DeerFlow vendor 源码。
