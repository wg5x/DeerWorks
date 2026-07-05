# AgentScope 技术方案导览

这份文档用于记录 AgentScope 作为 DeerWorks 后续 Agent 平台的另一套技术方案。它不是上游 README 的复刻，而是从 DeerWorks 的视角整理：这套技术栈能提供什么、两个 vendor 项目是什么关系、应该先研究哪些入口，以及它和当前 DeerFlow 基线的差异。

## 当前 vendor

| 项目 | 路径 | 当前定位 | 版本锁 |
| --- | --- | --- | --- |
| AgentScope 2.0 | `vendor/agentscope/` | 重点研究对象，面向生产的 Agent 框架 | `vendor/agentscope.lock` |
| AgentScope Runtime | `vendor/agentscope-runtime/` | 参考项目，主要看运行时、沙箱、AaaS、适配器设计 | `vendor/agentscope-runtime.lock` |

两个源码目录都是独立 Git 仓库，不进入 DeerWorks 顶层 Git 历史。顶层只提交 `.lock` 文件，用来记录当前 checkout 的 upstream、路径、分支和 commit。

## 项目关系

AgentScope Runtime 的 README 顶部已有归档公告：随着 AgentScope 2.0 发布，Runtime 的核心能力，包括工具沙箱化、Agent 即服务 API 和全栈可观测性，已经原生集成到 AgentScope 2.0。上游建议迁移到 AgentScope 2.0，Runtime 仓库后续会以只读方式保留并归档。

因此 DeerWorks 后续评估时应把 AgentScope 2.0 作为主线方案，把 AgentScope Runtime 当作历史设计和工程实现参考。Runtime 仍然有价值，尤其适合研究它如何抽象 AgentApp、沙箱服务、部署适配器、跨框架 adapter 和可观测链路，但不宜优先作为新的核心依赖。

## AgentScope 2.0 能力摘要

AgentScope 2.0 是一个 Python Agent 框架，强调生产可用和可扩展抽象。当前 README 中最值得 DeerWorks 关注的能力包括：

- 事件系统：统一事件总线，适合前端流式 UI 和 human-in-the-loop 协作。
- 权限系统：对工具和资源做细粒度控制。
- 多租户与多会话服务：提供 tenant/session 级隔离，是企业 Agent 平台的重要基础。
- 工作区与沙箱：支持本地文件系统、Docker 和 E2B 后端。
- Middleware：通过可组合钩子扩展 agent 的推理和行动循环。
- MCP 与 A2A：有利于接入外部工具生态和跨 agent 协作。
- RAG 与长期记忆：包含 RAG、Agentic Memory、Mem0、ReMe 等方向的示例或集成。

## AgentScope Runtime 参考价值

AgentScope Runtime 更像一套生产运行时参考实现。它的重点不是新的 Agent 抽象，而是如何把 Agent 应用变成可部署、可观测、可管理的服务。

值得研究的能力包括：

- AgentApp：把 Agent 暴露成支持流式输出的 API 服务。
- 沙箱体系：Python、Shell、GUI、Browser、Filesystem、Mobile 等工具执行隔离。
- 部署管理：本地、Kubernetes、Serverless 等部署路径。
- 状态服务：会话、历史、长期记忆和沙箱生命周期管理。
- 框架适配：包含 AgentScope、LangGraph、Microsoft Agent Framework、Agno、AutoGen 等 adapter。
- 可观测性：运行时日志、链路追踪和服务状态设计。

这些能力很多已经进入 AgentScope 2.0，但 Runtime 的代码仍适合做架构参考，尤其适合 DeerWorks 以后设计“多框架接入层”或“统一运行时层”时对照。

## 与 DeerFlow 的关系

当前 DeerWorks 的基线是 DeerFlow。DeerFlow 已经提供全栈产品形态，包括后端 agent harness、LangGraph runtime、sandbox、skills、MCP、subagent、memory、IM channel 和 Next.js 前端工作区。

AgentScope 方案更像另一条技术路线：

| 维度 | DeerFlow | AgentScope 2.0 |
| --- | --- | --- |
| 当前角色 | DeerWorks 的基线项目 | 后续备选 Agent 平台方案 |
| 产品完整度 | 自带完整前后端和工作区 UI | 更偏 Agent 框架和服务能力，示例中包含 Web UI |
| 编排风格 | LangGraph-based super-agent harness | AgentScope 自有 Agent、事件、middleware、service 抽象 |
| 企业平台能力 | 已有 sandbox、MCP、skills、subagent、memory、channels | 多租户、多会话、权限、workspace、middleware 是重点 |
| 研究价值 | 适合快速形成可运行平台 | 适合验证下一代平台抽象和多租户服务模型 |

短期建议：继续以 DeerFlow 为运行基线，同时把 AgentScope 2.0 作为技术雷达和方案对照。不要急着迁移或混用两套框架，先做小规模 PoC 验证关键能力。

## 源码入口

AgentScope 2.0：

| 路径 | 关注点 |
| --- | --- |
| `vendor/agentscope/src/agentscope/agent/` | Agent 核心抽象 |
| `vendor/agentscope/src/agentscope/event/` | 事件模型和流式输出基础 |
| `vendor/agentscope/src/agentscope/middleware/` | 推理-行动循环扩展点 |
| `vendor/agentscope/src/agentscope/permission/` | 工具和资源权限控制 |
| `vendor/agentscope/src/agentscope/workspace/` | workspace 和 sandbox 后端 |
| `vendor/agentscope/src/agentscope/mcp/` | MCP 集成 |
| `vendor/agentscope/src/agentscope/app/` | 多租户、多会话服务能力 |
| `vendor/agentscope/examples/agent_service/` | Agent service 示例 |
| `vendor/agentscope/examples/rag/` | RAG 示例 |
| `vendor/agentscope/examples/web_ui/` | Web UI 示例 |

AgentScope Runtime：

| 路径 | 关注点 |
| --- | --- |
| `vendor/agentscope-runtime/src/agentscope_runtime/engine/` | AgentApp、服务、部署和 tracing |
| `vendor/agentscope-runtime/src/agentscope_runtime/sandbox/` | 沙箱抽象、客户端、管理器和模型 |
| `vendor/agentscope-runtime/src/agentscope_runtime/adapters/` | 多框架 adapter，包括 LangGraph |
| `vendor/agentscope-runtime/src/agentscope_runtime/tools/` | 内置工具和工具服务 |
| `vendor/agentscope-runtime/examples/sandbox/` | 沙箱示例 |
| `vendor/agentscope-runtime/examples/deployments/` | 部署配置示例 |
| `vendor/agentscope-runtime/examples/interrupt/` | 中断与恢复示例 |

## 后续验证方向

建议后面按小 PoC 验证，而不是一次性做平台重构：

1. 跑通 AgentScope 2.0 最小 Agent service，确认事件流、模型配置和工具调用体验。
2. 对照 DeerFlow 的 thread/run/state 模型，整理 AgentScope 的 tenant/session/message/event 模型。
3. 验证 workspace/sandbox：本地、Docker、E2B 三种后端是否满足 DeerWorks 的隔离需求。
4. 验证权限系统：是否能表达企业工具审批、敏感命令限制、资源访问控制。
5. 验证 MCP 接入：和 DeerFlow MCP 工具加载方式对比，判断能否复用 DeerWorks 后续的工具目录。
6. 研究 Runtime adapter：重点看 LangGraph adapter，评估未来是否需要做统一运行时层。
7. 形成 DeerFlow vs AgentScope 的架构决策记录，再决定是否进入迁移、双栈或只借鉴设计。

## 当前判断

AgentScope 2.0 值得作为 DeerWorks 的第二技术路线持续研究，尤其在多租户、多会话、权限、事件和 workspace 抽象上。AgentScope Runtime 不建议作为新平台主依赖，但它的运行时工程实现值得参考。短期 DeerWorks 仍应保持 DeerFlow 基线稳定，围绕 AgentScope 做独立 PoC 和架构对比。
