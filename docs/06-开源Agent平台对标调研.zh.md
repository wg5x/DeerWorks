# 开源 Agent 平台对标调研

这份文档用于避免 DeerWorks 闭门造车。调研重点不是找一个可以直接替代 DeerWorks 的项目，而是对照开源社区里相近项目的产品边界、技术取舍和可借鉴点，判断 DeerWorks 的设计是否站得住。

调研结论：DeerWorks 的方向是合理的。外部项目已经验证了“Agent 管理 + API 暴露 + MCP/tools + RAG/外部能力接入”这类需求真实存在。DeerWorks 的差异点是更克制：它不做大而全的应用构建平台，而是在 DeerFlow 之上做企业级 Agent API 二次开发层。

## DeerWorks 当前定位

DeerWorks 当前定位：

```text
Application SaaS
  -> DeerWorks Agent API
  -> DeerFlow Agent Runtime
  -> MCP Tools
  -> RAG / Database / Business APIs / Tool Services
```

DeerWorks 负责 Agent 集合、API 包装、MCP 工具治理、应用访问控制、审计和部署管理；RAG、业务数据库和具体应用 SaaS 保持在仓库外部。

## 对标项目

| 项目 | 定位 | 和 DeerWorks 的关系 | 结论 |
| --- | --- | --- | --- |
| Open Agent Platform | no-code Agent 构建和管理平台 | 最像“Agent 集合管理 + RAG + MCP tools + 认证”的参考 | 设计很有参考价值，但仓库已 deprecated，不建议直接依赖 |
| OAP LangGraph Tools Agent | 面向 Open Agent Platform 的预置 LangGraph tools agent | 证明 LangGraph/OAP 路线可以把 MCP servers 和 RAG tool 打包成 agent | 可参考 Agent 配置和 MCP/RAG 接入方式 |
| Dify | 生产级 agentic workflow / LLM app 平台 | 证明 Agent、Workflow、RAG、API、企业能力能组成完整产品 | 边界比 DeerWorks 大，适合借鉴产品能力，不适合照搬 |
| Flowise | 可视化 AI Agent / workflow 构建平台 | 证明低代码和可视化编排有市场 | DeerWorks 不走可视化主路线，但可借鉴组件和 API 文档组织 |
| mcp-agent | MCP-first Agent 框架 | 和 DeerWorks 的 MCP 外部能力接入理念高度一致 | 非常值得研究工具治理、多 MCP 编排、durable execution |
| CrewAI | 面向 Crews / Flows 的多 Agent 编排框架 | 更适合固定业务流程和轻量 Python 编排 | 不建议作为 DeerWorks 主 runtime，避免双 runtime 复杂化 |
| MetaGPT | 面向软件研发 SOP 的多 Agent 框架 | 更适合“需求 -> PRD -> 架构 -> 代码”的软件公司式流程 | 不适合作为 DeerWorks 深度调研和报告平台主底座 |

## Open Agent Platform

仓库：[langchain-ai/open-agent-platform](https://github.com/langchain-ai/open-agent-platform)

Open Agent Platform 原 README 将它描述为 no-code agent building platform。它的 Agent 可以连接 tools、RAG servers，也可以通过 Agent Supervisor 连接其他 Agent。功能列表包括 Agent Management、RAG Integration、MCP Tools、Agent Supervision、Authentication 和 Configurable Agents。

需要注意：该仓库目前已经标记 deprecated，上游建议使用 LangSmith 上的 Agent Builder。即便如此，它仍是 DeerWorks 的重要参考，因为它的产品抽象和 DeerWorks 很接近。

可借鉴点：

- Agent 是 existing LangGraph graph 之上的 custom configuration，这和 DeerFlow custom agent 的实现很像。
- Agent 管理、RAG、MCP tools、认证访问控制是同一类平台能力。
- UI 可以让非技术用户配置 Agent，但核心仍是 Agent config + runtime。

对 DeerWorks 的启发：

- DeerWorks 可以先不做 no-code UI，但应把 Agent registry 和 Agent config 设计稳定。
- 应用不应直接依赖 runtime 细节，而应通过稳定 Agent API 调用。
- Agent 级可配置项要从一开始留好：模型、工具、MCP、RAG、system prompt / SOUL、权限。

## OAP LangGraph Tools Agent

仓库：[langchain-ai/oap-langgraph-tools-agent](https://github.com/langchain-ai/oap-langgraph-tools-agent)

这是一个面向 Open Agent Platform 的预置 LangGraph tools agent。README 中说明它包含 MCP servers 支持和 LangConnect RAG tool。

可借鉴点：

- 用一个预置 tools agent 承接 MCP 和 RAG。
- 面向平台注册 Agent，而不是让应用直接关心内部 graph。
- 自定义 graph config，让平台可以识别 Agent 的可配置字段。

对 DeerWorks 的启发：

- DeerWorks 第一阶段可以做一个 `document-qa-agent` 或 `tools-agent` 作为样板。
- RAG 不需要内置进 DeerWorks，只需要通过 MCP/RAG tool 暴露给 Agent。
- Agent 配置应该被平台化管理，而不是散落在 prompt 和临时代码里。

## Dify

仓库：[langgenius/dify](https://github.com/langgenius/dify)

Dify 是一个生产级 agentic workflow development 平台。它同时提供 Cloud、自托管社区版和企业能力。官方站点描述它包含 agentic workflows、RAG pipelines、integrations 和 observability。

可借鉴点：

- LLM 应用平台的完整产品形态：Agent、Workflow、RAG、模型、应用发布、观测。
- Cloud/self-host/enterprise 三种交付形态。
- 企业客户会关心组织、权限、品牌、部署和运营能力。

对 DeerWorks 的启发：

- DeerWorks 不应一开始做成 Dify 那样的大平台。
- 但可以参考它的产品模块命名、应用发布方式、观测和企业功能。
- DeerWorks 的差异点应保持清楚：不内置 RAG pipeline，不做低代码应用构建器，而是提供 Agent API 服务层。

## Flowise

仓库：[FlowiseAI/Flowise](https://github.com/FlowiseAI/Flowise)

Flowise 的定位是可视化构建 AI Agents。仓库 README 说明它包含 server、ui、components 和 API documentation 等模块，主题覆盖 agents、workflow automation、low-code、no-code、RAG 等。

可借鉴点：

- 可视化组件化是构建 Agent/Workflow 的常见产品路线。
- 组件、节点、API 文档和自托管部署对开发者友好。
- RAG、tools、workflow 都可以作为可组合组件出现。

对 DeerWorks 的启发：

- DeerWorks 暂时不应以可视化编排为核心，否则范围会迅速扩大。
- 后续如果要做管理 UI，可以先做 Agent registry、tool allowlist、MCP config 的表单化管理。
- Flowise 也提醒我们：可视化平台里的自定义工具/MCP 入口必须非常重视安全边界。

## mcp-agent

仓库：[lastmile-ai/mcp-agent](https://github.com/lastmile-ai/mcp-agent)

mcp-agent 是 MCP-first 的 Agent 框架。README FAQ 中说明它用 MCP server 暴露的能力来构建 Agent，并处理连接 MCP servers、LLM、human input、durable execution 等机制，让开发者关注业务逻辑。

可借鉴点：

- MCP 是外部工具和能力的统一连接层。
- Agent 可以连接多个 MCP servers。
- 支持 composability、customizability、人类输入信号和 durable execution。
- 可以作为 MCP server 暴露复杂 Agent workflow，形成 server-of-servers。

对 DeerWorks 的启发：

- DeerWorks 的“RAG、DB、业务系统都通过 MCP 进入 Agent”是正确方向。
- Agent 级 MCP tool allowlist 应该成为一等能力。
- 后续可以研究 durable execution、human signal、multi-MCP 编排和 Agent-as-MCP-server。

## CrewAI / MetaGPT / DeerFlow 选型补充

本轮补充调研重点是：如果 DeerWorks 已经明确要做“深度调研、报告生成和其他智能体能力”，是否还需要在 CrewAI、MetaGPT 和 DeerFlow 之间重新选底座。

结论：DeerWorks 主线继续选择 DeerFlow。CrewAI 和 MetaGPT 暂时不作为主 runtime 引入。

### 三者定位

| 平台 | 更适合的任务 | 不适合直接承担的部分 | 对 DeerWorks 的建议 |
| --- | --- | --- | --- |
| DeerFlow | 深度调研、长任务、多文件产物、子 Agent 委派、sandbox、skills、MCP、memory | 需要 DeerWorks 自己补齐企业 API、权限、审计和 Agent registry | 作为主 runtime |
| CrewAI | 固定步骤的业务自动化、多角色协作、Python 侧轻量编排、可控流程 | 深度研究工作台、文件 artifact、sandbox、长期任务治理需要额外补 | 暂不引入；后续只在独立 PoC 中验证特定流程编排 |
| MetaGPT | 软件研发 SOP，例如从一句需求生成 PRD、设计、任务和代码 | 通用企业 Agent API、MCP 工具治理、报告平台和多应用接入 | 作为软件研发类 Agent 的参考，不作为平台底座 |

### 为什么不是 CrewAI 做主线

CrewAI 的优势是把多个角色和步骤组织成 `Crews` 和 `Flows`。这对“确定步骤的业务流程”很友好，例如线索分析、邮件生成、工单分类、销售跟进建议。

但 DeerWorks 当前核心场景不是简单流程编排，而是：

- 深度调研和报告生成，需要长时间运行、阶段性产物和引用材料。
- 多 Agent 组合，需要 research-agent、report-agent、document-qa-agent、data-agent 等作为 API 暴露。
- 外部能力接入，需要 RAG、搜索、数据库、文件和业务系统通过 MCP 受控进入 Agent。
- 企业治理，需要 app -> agent、agent -> tool、tenant/user -> data scope 的权限和审计。

如果用 CrewAI 作为主 runtime，DeerWorks 仍然需要自行补齐 sandbox、artifact、长任务状态、MCP 治理、前端工作区和运行时 API 包装。这样会把“业务平台建设”变成“重建一套 DeerFlow 周边能力”，投入不划算。

### 为什么不是 MetaGPT 做主线

MetaGPT 的强项是软件工程协作范式。它更像一个把团队角色、文档和代码生产流程固化下来的软件公司式 Agent 框架。

这和 DeerWorks 的主场景不完全一致。DeerWorks 要暴露的是多个可被 SaaS、飞书、客户门户和内部系统调用的 Agent API，而不是只做软件项目生成。MetaGPT 可以启发后续的“软件研发 Agent”或“PRD/架构 Agent”，但不适合作为全平台 runtime。

### 为什么 DeerFlow 更贴合当前项目

DeerFlow 已经覆盖 DeerWorks 第一阶段最需要复用的底层能力：

- `lead_agent` 和 custom agents 可以支持多个 Agent 配置。
- LangGraph-compatible runtime 可以承接 run、thread 和 stream。
- MCP、skills、sandbox、subagents、memory 已经是 runtime 能力的一部分。
- 前端已有线程化聊天、artifact 预览、文件和设置等工作区基础。
- 后端 Gateway 可以被 DeerWorks 包装成更稳定的业务 API。

因此，短期最稳妥的路线不是再引入 CrewAI 或 MetaGPT，而是：

```text
Application / Feishu / SaaS
  -> DeerWorks Agent API
  -> Agent Registry / Auth / Audit / Tool Policy
  -> DeerFlow Runtime
  -> research-agent / report-agent / document-qa-agent / data-agent
  -> MCP Tools / RAG / Search / Database / Files
```

### 飞书通讯能力的位置

飞书不应该被当成 Agent runtime 或 Agent 编排框架来比较。它更适合作为 DeerWorks 的企业通讯入口，也就是 Channel Adapter。

飞书开放平台的通讯能力可以支撑这些入口：

- 用户私聊机器人或在群里 @ 机器人，飞书通过消息事件把用户输入推给 DeerWorks。
- DeerWorks 调用飞书消息 API，把 Agent 回复发回私聊或群聊。
- 回复形态可以从纯文本开始，后续扩展到富文本、文件、图片和交互卡片。
- 群聊可以绑定默认 Agent，也可以配置一个允许使用的 Agent 列表。
- 飞书的 `chat_id`、用户身份、消息 ID 和租户信息可以进入 DeerWorks 的 `context` 和 `metadata`，用于会话、审计和权限判断。

推荐链路：

```text
Feishu Bot / Group Chat
  -> Feishu Event Subscription
  -> DeerWorks Feishu Channel Adapter
  -> app_id / chat_id / user_id / tenant_id / command parsing
  -> DeerWorks Agent API
  -> DeerFlow Runtime
  -> MCP Tools
  -> DeerWorks Feishu Channel Adapter
  -> Feishu Message / Card Reply
```

这说明飞书能力不改变前面的 runtime 选型结论：

- DeerFlow 继续负责深度调研、报告生成、长任务、subagents、sandbox、skills、MCP 和 memory。
- DeerWorks 负责把飞书消息转换成统一 Agent API 请求，并把 Agent 输出转换成飞书消息或卡片。
- CrewAI 或 MetaGPT 即使被引入，也仍然需要同样的飞书 Channel Adapter，因此不能因为“要接飞书”就切换主 runtime。

飞书接入时需要特别注意权限边界：

- `chat_id -> allowed_agent_ids`：某个飞书群只能访问被授权的 Agent。
- `agent_id -> allowed_mcp_tools`：被群调用的 Agent 仍然只能访问被授权的工具。
- `tenant_id / user_id -> data_scope`：用户和租户身份要进入 RAG、数据库和业务系统的权限判断。
- 飞书事件回调要做签名、token 或 challenge 校验，不能把公网请求直接转成 Agent 调用。
- 长报告任务不宜只靠一条同步消息返回，应该优先使用流式状态、进度卡片、任务链接或最终报告链接。

### 决策规则

后续如果再遇到 Agent 平台选型，可以按下面规则判断：

| 判断问题 | 选择 |
| --- | --- |
| 主要是深度调研、报告、资料整合、长任务和文件产物吗？ | DeerFlow |
| 主要是固定业务流程、步骤清晰、只需要轻量 Python 编排吗？ | CrewAI 可做独立 PoC |
| 主要是软件研发流程自动化，例如 PRD、架构、任务、代码生成吗？ | MetaGPT 可作为专项 Agent 参考 |
| 是否要给多个应用暴露稳定 Agent API，并治理 MCP/tools 权限？ | DeerWorks + DeerFlow |
| 是否要接入飞书、企业微信、Slack 等通讯入口？ | 作为 Channel Adapter 接入 DeerWorks |
| 是否已经有 DeerFlow 基线和 vendor 管理？ | 继续 DeerFlow，避免双 runtime |

### 当前取舍

当前 DeerWorks 选型记录如下：

- 主 runtime：DeerFlow。
- 企业能力层：DeerWorks 自己实现 Agent registry、API 包装、权限、审计和调用治理。
- 外部工具层：优先 MCP，不把 RAG、数据库或业务系统做进 DeerWorks 仓库。
- CrewAI：暂不进入主架构；只保留为流程编排类 PoC 备选。
- MetaGPT：暂不进入主架构；只保留为软件研发类 Agent 设计参考。

## 与 DeerWorks 的差异定位

DeerWorks 不应复制任何一个项目，而应保持自己的边界：

| 维度 | DeerWorks 选择 |
| --- | --- |
| Runtime | 当前基于 DeerFlow |
| Agent 管理 | DeerWorks 提供 Agent registry 和 API 包装 |
| RAG | 外部服务，通过 MCP 访问 |
| 数据库 | 应用可直连；Agent 通过受控 MCP tool 访问 |
| 应用构建 | 不做完整应用 SaaS，本仓库只提供 Agent API 能力 |
| 通讯入口 | 飞书等 IM 作为 Channel Adapter 接入，不作为 runtime |
| 可视化 | 不是第一阶段重点 |
| MCP | 是核心外部能力接入方式 |
| 企业治理 | DeerWorks 重点补齐 app -> agent、agent -> tool 的权限和审计 |

## 设计验证

这些项目共同验证了几个判断：

1. Agent 管理和 Agent API 是真实需求。
2. RAG 和 tools 通常不会只是 Agent 的附属功能，而是平台化能力。
3. MCP 正在成为外部工具接入的重要协议。
4. 大而全平台容易扩大边界，DeerWorks 需要保持克制。
5. 企业级二次开发重点不是重写 runtime，而是补齐治理层。

因此 DeerWorks 当前路线可以成立：

```text
DeerFlow runtime
  + DeerWorks Agent registry/API wrapper
  + MCP-first external capabilities
  + enterprise governance
```

## 后续建议

第一阶段继续沿 DeerFlow 做 Agent API 服务，不急着引入 CrewAI、MetaGPT 或其他新 runtime：

1. 设计 DeerWorks Agent registry。
2. 包装 `/api/agents/{agent_id}/runs` 和 `/api/agents/{agent_id}/runs/stream`。
3. 接入一个 RAG MCP，验证 `document-qa-agent`。
4. 设计 app -> agent 与 agent -> MCP tool 的 allowlist。
5. 加入调用审计和 run metadata。
6. 设计 `research-agent`、`report-agent`、`document-qa-agent` 作为第一批样板 Agent。
7. 接入飞书 Channel Adapter，验证群聊调用 Agent、权限控制和报告回传。
8. 再对照 Open Agent Platform / mcp-agent / CrewAI / MetaGPT 设计第二阶段能力。

参考链接：

- [Open Agent Platform](https://github.com/langchain-ai/open-agent-platform)
- [OAP LangGraph Tools Agent](https://github.com/langchain-ai/oap-langgraph-tools-agent)
- [Dify](https://github.com/langgenius/dify)
- [Flowise](https://github.com/FlowiseAI/Flowise)
- [mcp-agent](https://github.com/lastmile-ai/mcp-agent)
- [CrewAI](https://github.com/crewAIInc/crewAI)
- [CrewAI Docs](https://docs.crewai.com/)
- [MetaGPT](https://github.com/FoundationAgents/MetaGPT)
- [MetaGPT Docs](https://docs.deepwisdom.ai/main/en/guide/get_started/introduction.html)
- [DeerFlow](https://github.com/bytedance/deer-flow)
- [Feishu Receive Message Event](https://open.feishu.cn/document/server-docs/im-v1/message/events/receive)
- [Feishu Send Message API](https://open.feishu.cn/document/server-docs/im-v1/message/create)
- [Feishu Reply Message API](https://open.feishu.cn/document/server-docs/im-v1/message/reply)
