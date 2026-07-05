# DeerWorks MCP 与工具接入调研

这份文档整理 DeerWorks 基于 DeerFlow 接入 MCP tools、通用数据库和 RAG 的可行性与设计边界。核心结论是：RAG 和通用数据库不应放进 DeerWorks 仓库实现，而应作为外部 MCP server 被 Agent 调用。

## MCP 在 DeerWorks 中的角色

DeerWorks 的 Agent 不直接依赖具体外部系统 SDK，而是通过 MCP 暴露工具能力。

```text
Agent
  -> MCP Tool
  -> External Service
```

典型外部能力包括：

- RAG / Knowledge Base
- PostgreSQL
- Redis
- 文件存储
- 搜索服务
- CRM / ERP / 工单系统
- 内部 HTTP API
- 浏览器、爬虫和自动化工具

这样可以让 Agent runtime 保持通用，上层应用和外部系统保持松耦合。

## DeerFlow MCP 现状

DeerFlow 通过 `extensions_config.json` 或 `mcp_config.json` 配置 MCP servers。配置结构支持：

| 字段 | 说明 |
| --- | --- |
| `enabled` | 是否启用 server |
| `type` / `transport` | `stdio`、`sse`、`http` |
| `command` / `args` | stdio server 启动命令 |
| `env` | 环境变量 |
| `url` | SSE 或 HTTP server 地址 |
| `headers` | HTTP headers |
| `oauth` | HTTP/SSE OAuth token 注入 |
| `description` | server 描述 |
| `tool_call_timeout` | stdio tool 调用超时 |

示例方向：

```json
{
  "mcpServers": {
    "rag": {
      "enabled": true,
      "type": "http",
      "url": "https://rag.example.com/mcp",
      "headers": {
        "Authorization": "$RAG_MCP_TOKEN"
      },
      "description": "RAG knowledge base search"
    },
    "postgres": {
      "enabled": true,
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://localhost/app"],
      "description": "PostgreSQL database access"
    }
  },
  "skills": {}
}
```

## RAG MCP 设计

RAG 应作为独立知识服务存在，不属于 DeerWorks 仓库内部模块。DeerWorks 只关心它以 MCP tool 形式暴露哪些能力。

建议 RAG MCP 至少提供这些工具：

| 工具 | 作用 |
| --- | --- |
| `rag_search` | 根据 query 检索知识片段 |
| `rag_answer` | 直接返回问答结果和引用 |
| `rag_get_document` | 根据 doc_id 获取文档详情 |
| `rag_list_sources` | 查询可用知识源 |
| `rag_ingest_status` | 查询文档导入状态，供运维 Agent 使用 |

Agent 调用时应能拿到：

- answer 或 chunks
- citation/source
- score
- document metadata
- permission scope
- updated_at

## 通用数据库 MCP

通用数据库 MCP 适合给特定 Agent 做受控查询。需要注意它和 RAG 的职责不同：

- PostgreSQL / Redis 是业务状态和结构化数据。
- RAG 是知识问答和非结构化检索。
- Agent 可以同时调用两者，但权限和审计要分开。

数据库也可能被上层 Application SaaS 直接访问。这个路径和 Agent 通过 MCP 访问数据库不是一回事：

| 访问路径 | 适用场景 | 权限模型 |
| --- | --- | --- |
| Application backend -> database | 应用自己的业务逻辑、事务、状态读写 | 应用后端账号、业务权限、ORM/SQL/Redis client |
| Agent -> MCP tool -> database | Agent 完成任务时的受控查询或操作 | MCP 工具账号、tool allowlist、审计、限流、脱敏 |

同一个数据库可以同时服务这两条路径，但不应该让 Agent 直接拿到应用后端的完整数据库权限。Agent 侧更适合暴露小而明确的工具。

数据库 MCP 应尽量避免暴露任意 SQL 给普通 Agent。更推荐暴露受限工具：

```text
customer_lookup
order_status_query
ticket_search
inventory_check
```

如果确实使用通用 SQL MCP，应增加：

- 只读账号。
- schema allowlist。
- query timeout。
- row limit。
- sensitive column masking。
- audit logging。

## Agent 级工具权限

DeerFlow 当前会从全局 extensions config 加载 enabled MCP tools。也就是说，默认情况下 enabled MCP tools 会进入候选工具集合。

DeerWorks 需要设计 Agent 级工具权限，否则“某个 Agent 可以访问哪些 MCP”会过于宽。

可选方案：

### 方案 A：Skill allowed-tools

为每个 Agent 配置 skills，并在 skill 中声明 allowed tools。DeerFlow 已有 `allowed-tools` 过滤逻辑。

优点：

- 不需要改 DeerFlow vendor。
- 能快速控制 Agent 可见工具。

缺点：

- 权限规则分散在 skill 文档中。
- 不适合作为长期企业权限模型的唯一来源。

### 方案 B：DeerWorks Agent Registry

DeerWorks 自己维护：

```text
agent_id -> allowed_mcp_tools
agent_id -> allowed_mcp_servers
agent_id -> allowed_builtin_tools
```

调用 DeerFlow 前，把这些限制转成 Agent config、skills 或运行上下文。

优点：

- 规则集中，适合审计和 UI 管理。
- 后续可以接入应用权限、客户权限和环境权限。

缺点：

- 需要实现包装层和校验逻辑。

### 方案 C：扩展 DeerFlow MCP filtering

修改 DeerFlow 的 tool loading，让 MCP server / tool 可以按 agent_name 过滤。

优点：

- runtime 层最干净。

缺点：

- 需要改 vendor 或维护 fork。
- 会增加升级上游的成本。

第一阶段推荐 B + A：DeerWorks 维护集中策略，落地时先转换为 DeerFlow 可用的 skills/tool policy。等边界稳定后，再评估是否需要 C。

## 工具命名建议

为了让 Agent 配置和审计清楚，MCP tool 命名应有稳定前缀：

```text
rag_search
rag_answer
db_customer_lookup
db_order_status
crm_get_account
file_read_policy_doc
search_web
```

不要让不同 MCP server 暴露同名工具。DeerFlow 会对重复 tool name 做去重，重复名称会造成 Agent 看到的能力不清楚。

## 安全边界

MCP 是外部能力入口，也是风险入口。DeerWorks 至少需要关注：

- 哪些 Agent 可以调用哪些 MCP tools。
- 哪些应用可以调用哪些 Agent。
- MCP server 凭据如何保存和注入。
- RAG 和数据库查询是否带有应用/客户上下文。
- 工具调用是否记录审计日志。
- 工具超时和失败是否可控。
- 是否允许 stdio MCP server，以及允许哪些命令。

DeerFlow 对 API 管理的 stdio MCP command 有 allowlist 机制，默认允许 `npx` 和 `uvx`。生产环境建议优先使用 HTTP/SSE MCP，并放在可信网络和鉴权边界后。

## 第一阶段建议

第一阶段的 MCP 工具接入可以这样做：

1. 先接一个 RAG MCP，提供 `rag_search` 和 `rag_answer`。
2. 创建一个 `document-qa-agent`，只允许访问 RAG 相关工具。
3. 再接一个只读数据库 MCP，提供受限业务查询工具。
4. 创建一个 `support-agent`，允许访问 RAG 和受限数据库工具。
5. 在 DeerWorks 记录每个 Agent 的 tool allowlist。
6. 所有 Agent 调用都记录 run metadata，包括 app_id、agent_id、tool policy version。

这能验证 DeerWorks 的核心闭环：

```text
Application
  -> Agent API
  -> DeerFlow Agent
  -> MCP RAG / MCP DB
  -> Answer / Action
```
