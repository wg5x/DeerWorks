# DeerWorks

DeerWorks 是一个基于 DeerFlow 的企业级 Agent 平台。

Enterprise Agent Platform based on DeerFlow.

这个顶层项目用于承载围绕 DeerFlow 的企业平台代码、本地集成、配置、部署、说明文档和后续自有扩展。

DeerFlow 源码放在 `vendor/deer-flow/`，它是一个独立 Git 仓库，remote 指向官方上游：

```bash
cd vendor/deer-flow
git remote -v
```

顶层项目通过 `.gitignore` 忽略 `vendor/deer-flow/`，避免把上游项目源码混进自己的 Git 历史。这样 DeerFlow 可以独立升级，顶层项目也可以独立演进。

## 本地结构

```text
DeerWorks/
├── README.md
├── docs/
│   └── deerflow-vendor-guide.zh.md
├── scripts/
│   ├── check_deerflow_clean.sh
│   └── update_deerflow.sh
├── tests/
│   └── test_deerflow_vendor_scripts.sh
└── vendor/
    ├── deer-flow.lock    # DeerFlow 上游版本锁
    └── deer-flow/        # 独立的 DeerFlow 上游仓库，不由顶层 git 跟踪
```

## DeerFlow 版本管理

当前使用的 DeerFlow 上游 commit 记录在 [vendor/deer-flow.lock](vendor/deer-flow.lock)。

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

- `vendor/deer-flow/` 尽量保持干净，只跟随官方上游升级。
- 企业配置、部署、自定义 skills、MCP 适配和平台代码放在顶层项目里。
- 如果确实必须修改 DeerFlow 源码，优先切到自己的 DeerFlow fork，并在 `vendor/deer-flow.lock` 或变更记录中写清楚原因。

## DeerFlow Vendor 导览

见 [docs/deerflow-vendor-guide.zh.md](docs/deerflow-vendor-guide.zh.md)。

## 测试

顶层脚本测试：

```bash
bash tests/test_deerflow_vendor_scripts.sh
```
