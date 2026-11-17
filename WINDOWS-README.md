# Windows 本机构建

当前目录基于官方 `Windows_Linux` 分支提交 `a46627d`，使用原生
Vulkan 引擎和 Tauri 界面，已包含片边、日期后背和场景置位。旧
`windows_UI/` Qt/QML 工程不参与本构建。

本版还移植了 SpektraStudio 的整套设置持久化能力，但复用 SpektraLab
现有 sidecar 数据模型，不引入 Python/Pillow，也不改变编辑器布局。文件
菜单可将当前设置保存为启动默认、导出或导入 JSON，以及恢复出厂默认。

在 PowerShell 中运行：

```powershell
.\build-windows-app.ps1 -Fresh -Jobs 4
```

固定版本的第三方依赖准备完成后，可缩短后续构建：

```powershell
.\build-windows-app.ps1 -SkipDependencies -Fresh -Jobs 4
```

脚本会验证 Vulkan SDK、Rust 和 Node/npm，下载并校验官方固定的
Node v24.19.0 便携 CLI 运行时，构建 Vulkan 引擎与 Host，运行引擎和
Tauri 测试，并生成 NSIS 安装包：

`desktop\release\windows\SpektraLab_1.3.4_x64-setup.exe`

本目录只保留 Windows 本机构建/暂存所需的小型适配、设置预设功能，以及胶片封面
图标的 14px 显示调整。`engine/PORT_*` 中写着“未移植”的内容是上游
早期迁移记录；当前能力以 `windows_unported.hpp`、运行时 capabilities
和测试结果为准。
