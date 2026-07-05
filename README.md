# DeerWorks

DeerWorks 是一个基于 DeerFlow 的企业级 Agent 平台。

Enterprise Agent Platform based on DeerFlow.

这个顶层项目用于承载围绕 DeerFlow 的企业平台代码、本地集成、配置、部署、说明文档和后续自有扩展。AgentScope 作为后续 Agent 平台的另一套技术方案放在 vendor 中研究和对比。

上游开源项目源码放在 `vendor/` 下，每个目录都是独立 Git 仓库，remote 指向官方上游：

```bash
cd vendor/deer-flow
git remote -v
```

顶层项目通过 `.gitignore` 忽略 vendor 源码目录，避免把上游项目源码混进自己的 Git 历史。各上游项目用对应 `.lock` 文件记录当前 checkout 的 repo、path、ref 和 commit。

## 本地结构

```text
DeerWorks/
├── README.md
├── docs/
│   ├── 01-DeerFlow上游源码导览.zh.md
│   ├── 02-DeerWorks-Agent集合服务调研.zh.md
│   ├── 03-DeerWorks-Agent-API设计草案.zh.md
│   ├── 04-DeerWorks-MCP与工具接入调研.zh.md
│   ├── 05-DeerWorks业务应用场景设计.zh.md
│   ├── 06-开源Agent平台对标调研.zh.md
│   └── 07-AgentScope技术方案调研.zh.md
├── scripts/
│   ├── check_deerflow_clean.sh
│   └── update_deerflow.sh
├── tests/
│   └── test_deerflow_vendor_scripts.sh
└── vendor/
    ├── agentscope.lock
    ├── agentscope-runtime.lock
    ├── deer-flow.lock    # DeerFlow 上游版本锁
    ├── agentscope/       # 独立的 AgentScope 上游仓库，不由顶层 git 跟踪
    ├── agentscope-runtime/  # 独立的 AgentScope Runtime 上游仓库，不由顶层 git 跟踪
    └── deer-flow/        # 独立的 DeerFlow 上游仓库，不由顶层 git 跟踪
```

## Vendor 版本管理

当前使用的 DeerFlow 上游 commit 记录在 [vendor/deer-flow.lock](vendor/deer-flow.lock)。
AgentScope 和 AgentScope Runtime 的当前 checkout 分别记录在 [vendor/agentscope.lock](vendor/agentscope.lock) 与 [vendor/agentscope-runtime.lock](vendor/agentscope-runtime.lock)。

升级前先确认 vendor 仓库没有本地改动：

```bash
scripts/check_deerflow_clean.sh
```

升级到官方 `main` 最新版本，并刷新 `vendor/deer-flow.lock`：

```bash
scripts/update_deerflow.sh
```

升级到指定分支、tag 或 commit：

```bash
scripts/update_deerflow.sh --ref <branch-or-tag-or-commit>
```

离线刷新版本锁，不执行 `fetch` 或 `pull`：

```bash
scripts/update_deerflow.sh --no-fetch
```

原则：

- `vendor/*/` 上游源码目录尽量保持干净，只跟随官方上游升级。
- 企业配置、部署、自定义 skills、MCP 适配和平台代码放在顶层项目里。
- 如果确实必须修改上游源码，优先切到自己的 fork，并在对应 lock 文件或变更记录中写清楚原因。

## 文档阅读顺序

1. [DeerFlow 上游源码导览](docs/01-DeerFlow上游源码导览.zh.md)
2. [DeerWorks Agent 集合服务调研](docs/02-DeerWorks-Agent集合服务调研.zh.md)
3. [DeerWorks Agent API 设计草案](docs/03-DeerWorks-Agent-API设计草案.zh.md)
4. [DeerWorks MCP 与工具接入调研](docs/04-DeerWorks-MCP与工具接入调研.zh.md)
5. [DeerWorks 业务应用场景设计](docs/05-DeerWorks业务应用场景设计.zh.md)
6. [开源 Agent 平台对标调研](docs/06-开源Agent平台对标调研.zh.md)
7. [AgentScope 技术方案调研](docs/07-AgentScope技术方案调研.zh.md)

## 测试

顶层脚本测试：

```bash
bash tests/test_deerflow_vendor_scripts.sh
```
