# DeerWorks 业务应用场景设计

这份文档整理 DeerWorks 更贴近实际业务的应用场景。核心判断是：DeerWorks 应作为统一的 Agent API 能力层存在，上层应用可以是普通 SaaS、飞书机器人、客户门户、移动端，也可以是更卡通、更游戏化的定制 UI。

DeerWorks 不限定应用长什么样。它负责创建、运行和治理 Agent；应用负责把 Agent 能力组合成具体客户可使用的产品。

## 业务定位

DeerWorks 的定位可以概括为：

```text
DeerWorks = Agent 集合 + Agent API + MCP 工具治理
```

它不是 RAG 本身，不是业务数据库，也不是所有客户应用的统一前端。它更像企业智能能力中台：

- DeerWorks 创建和管理多个 Agent。
- 每个 Agent 都可以作为 API 被调用。
- Agent 通过 MCP 访问 RAG、数据库、搜索、文件、CRM、工单系统等外部能力。
- 上层应用调用 Agent API，把智能能力嵌入自己的业务流程和用户界面。

因此 DeerWorks 的核心原则是：

```text
Every Agent is an API.
Every Application can call Agents.
Every Tool should be governed.
```

## 整体架构

```text
Business Applications
  ├── 普通 SaaS / 管理后台
  ├── 飞书机器人 / 企业 IM
  ├── 客户门户 / 移动端
  ├── 游戏化 / 卡通 UI
  └── 行业定制应用
        │
        ▼
DeerWorks Agent API
  ├── agent_id
  ├── conversation_id
  ├── tenant_id
  ├── user_id
  ├── input
  ├── context
  ├── response_schema
  └── metadata
        │
        ▼
DeerFlow Runtime
  ├── custom agents
  ├── lead_agent
  └── run / stream
        │
        ▼
MCP Tools
  ├── RAG / Knowledge Base
  ├── PostgreSQL / Redis
  ├── CRM / ERP / 工单系统
  ├── 文件 / 搜索 / 爬虫
  └── 其他外部工具
```

上层应用不需要理解 DeerFlow 内部的 thread、checkpoint、graph 和 tool loading 细节。它只需要知道自己可以调用哪些 `agent_id`，以及调用时应该传入什么上下文。

## 典型应用形态

### 普通 SaaS 应用

普通 SaaS 应用通常有自己的 UI、后端和业务数据库。它不需要把全部业务逻辑交给 Agent，只在需要智能能力时调用 DeerWorks。

示例：

```text
CRM 系统
  -> 查询自己的 PostgreSQL
  -> 用户点击“生成客户跟进建议”
  -> CRM 后端调用 DeerWorks sales-agent
  -> sales-agent 通过 MCP 查询知识库或客户上下文
  -> 返回建议、摘要和下一步动作
```

这类场景中，应用业务数据库仍然属于应用后端。Agent 如果也需要访问数据库，应通过受控 MCP tool，而不是直接复用应用后端的完整数据库权限。

### 飞书机器人和群聊

飞书机器人适合作为 Channel Adapter。飞书本身不是 Agent runtime，它负责接收群消息、识别用户和群，然后调用 DeerWorks Agent API。

一个飞书群可以绑定一个默认 Agent，也可以配置一个允许使用的 Agent 列表：

```text
Channel Binding
├── channel_type: feishu
├── chat_id: oc_xxx
├── default_agent_id: project-agent
├── allowed_agent_ids:
│   ├── project-agent
│   ├── document-qa-agent
│   └── ticket-agent
├── conversation_id: feishu:oc_xxx
├── permissions
└── metadata
```

常见命令可以设计为：

```text
/agents
/use project-agent
/ask document-qa-agent 帮我总结这份文档
普通群消息 -> default_agent_id
```

这里的“自由指定 Agent”应该理解为：群成员可以在该群允许的 Agent 范围内切换或点名调用。不能让任意群随意访问任意 Agent，否则企业权限、客户隔离和工具权限都会失控。

### 游戏化和卡通 UI

游戏化 UI 是 DeerWorks 很适合支持的场景。应用可以把 Agent 包装成卡通角色、任务引导员、虚拟老师、销售顾问、客服 NPC 或项目助手。

典型交互链路：

```text
Game-like UI
  -> 用户点击角色、选择剧情、完成任务或输入问题
  -> UI / 应用后端转换成 Agent API 请求
  -> DeerWorks 调用指定 Agent
  -> Agent 返回文本、动作、状态和结构化数据
  -> UI 渲染成表情、对话、任务卡、奖励、动画或下一步按钮
```

这说明游戏化界面和 Agent 能力应该解耦：

- UI 决定视觉风格、交互节奏和角色表现。
- Agent 决定任务理解、工具调用、知识查询和业务推理。
- DeerWorks 决定调用入口、权限、审计、会话和工具治理。

## 结构化输出

如果上层只是普通聊天框，纯文本输出通常够用。但游戏化 UI、业务工作台和多卡片应用更适合使用结构化输出。

示例：

```json
{
  "speaker": "guide-agent",
  "dialogue": "太好了，我们先完成第一步。",
  "mood": "happy",
  "cards": [
    {
      "type": "task",
      "title": "上传企业资料",
      "status": "pending"
    }
  ],
  "actions": [
    {
      "label": "继续",
      "command": "next_step"
    }
  ]
}
```

这样 UI 可以按字段渲染：

- `dialogue` 渲染为角色对话。
- `mood` 决定角色表情或动画。
- `cards` 渲染任务、资料、推荐或结果卡片。
- `actions` 渲染按钮或下一步操作。

因此 DeerWorks API 后续可以支持 `response_schema` 或 `output_mode`：

```text
output_mode: text
output_mode: structured
output_mode: ui_event
```

第一阶段可以先在 Agent prompt / SOUL.md 中约束 JSON 输出。后续如果需要更稳定的工程能力，再在 DeerWorks API 层增加 schema 校验和错误修复。

## 统一调用模型

无论上层是 SaaS、飞书、移动端还是游戏化 UI，最终都应该收敛到统一调用模型：

```http
POST /api/agents/{agent_id}/runs
POST /api/agents/{agent_id}/runs/stream
```

请求里需要保留这些业务字段：

```json
{
  "conversation_id": "optional-conversation-id",
  "tenant_id": "tenant-a",
  "user_id": "user-123",
  "input": {
    "messages": [
      {
        "role": "user",
        "content": "帮我查一下这个客户最近的工单"
      }
    ]
  },
  "context": {
    "channel_type": "feishu",
    "chat_id": "oc_xxx",
    "app_id": "support-console"
  },
  "response_schema": "support-task-card-v1",
  "metadata": {
    "scenario": "after-sales",
    "trace_id": "trace-xxx"
  }
}
```

其中：

- `tenant_id` 用于租户隔离、RAG 权限和审计。
- `user_id` 用于用户权限和操作追踪。
- `conversation_id` 用于多轮上下文。
- `context` 描述调用来源，例如飞书群、Web 应用、移动端或客户门户。
- `response_schema` 描述应用期望的返回格式。
- `metadata` 用于日志、审计、观测和业务追踪。

## 权限和治理

业务应用越多，越需要把权限模型设计清楚。DeerWorks 至少需要治理三层关系：

```text
Application / Channel -> allowed_agent_ids
Agent -> allowed_mcp_tools
Tenant / User -> allowed_data_scope
```

对应到实际场景：

- 某个飞书群只能使用被授权的 Agent。
- 某个客户应用只能调用自己购买或配置的 Agent。
- 某个 Agent 只能调用被允许的 MCP tools。
- 某个 Agent 访问 RAG 时只能访问当前租户授权的数据范围。
- 公共知识库可以被多个租户使用，但仍应有明确的数据来源和权限标记。

审计日志需要记录：

- `run_id`
- `agent_id`
- `tenant_id`
- `user_id`
- `app_id`
- `channel_type`
- `conversation_id`
- 调用过的 MCP tools
- tool policy version
- 响应状态、耗时和错误

## 与 RAG 的关系

RAG 仍然应该是独立服务，不属于 DeerWorks 内部模块。DeerWorks 只需要通过 MCP 调用它。

租户级 RAG 可以这样理解：

```text
tenant-a
  -> own knowledge base
  -> own documents
  -> own permissions

tenant-b
  -> own knowledge base
  -> own documents
  -> own permissions

public knowledge base
  -> public / shared data
  -> maintained by crawler or operation agents
```

DeerWorks Agent 调用 RAG MCP 时，应把 `tenant_id`、`user_id` 和数据权限上下文传给 MCP server，由 RAG 服务执行真正的数据隔离和检索。

## 第一阶段落地建议

第一阶段建议优先验证完整业务闭环，而不是一开始做复杂平台：

1. 先实现 DeerWorks 统一 Agent API。
2. 建立 Agent registry，维护 `agent_id`、说明、可用状态和工具策略。
3. 接入一个 RAG MCP，验证 `document-qa-agent`。
4. 接入一个飞书 Channel Adapter，验证群聊调用 Agent。
5. 做一个轻量 Web Demo，验证普通 SaaS 调用 Agent。
6. 做一个游戏化 UI Demo，验证结构化输出驱动角色、卡片和动作。
7. 把调用日志、租户、用户、应用和工具调用记录下来。

这个阶段最重要的验证目标是：

```text
不同应用形态
  -> 调同一套 DeerWorks Agent API
  -> Agent 通过 MCP 访问外部能力
  -> 返回可被应用消费的结果
  -> 全链路可审计、可限权、可演进
```

## 结论

这套设计是可行的，也更贴近 DeerWorks 的实际业务价值。

DeerWorks 不应该只被理解成一个聊天机器人后端，而应该被设计成企业 Agent 能力层。它把 Agent 创建、API 调用、工具治理、会话和审计沉淀下来；上层应用则可以根据客户场景自由定制，包括普通 SaaS、飞书群机器人、行业门户、移动端和卡通游戏化界面。

只要 Agent API 足够统一，权限边界足够清楚，UI 层就可以非常灵活。后期不同客户的差异，更多体现在应用形态、业务流程和交互体验上，而不是每个项目都重新发明一套 Agent runtime。
