# 项目结构约定

集合根目录负责项目导航、Git 管理、共同开发约定和 Xcode workspace。每个复刻 App 放在 `apps/<app-name>/`，保持可单独打开与编译。

## 每个 App 的内容

- 独立 `.xcodeproj` 和共享 scheme。
- 原生源码与 Assets，按自身功能划分 Views、Models、Services。
- 独立单元测试与 UI 测试，不依赖其他复刻 App 的状态。
- `scripts/` 保存该 App 的项目生成、资源生成或验证辅助工具。
- `docs/` 保存视觉参考、截图与验证记录。
- `README.md` 说明运行方式、数据来源、最低系统版本和已知限制。

## 新增项目

1. 创建 `apps/<app-name>/`，例如 `apps/notes/`。
2. 在该目录创建原生 Xcode 项目，并启用共享 scheme。
3. 把项目加入根 `iOS6Apps.xcworkspace`；引用路径使用 `group:apps/<app-name>/<project>.xcodeproj`。
4. 更新根 README 的 App 表格。
5. 在该 App 目录内完成构建、实际界面验证和必要测试。

当前天气 App 的逻辑和拟物控件仍在 `apps/weather/`。后续出现真实共用需求时，再提取共享 Swift Package，避免让尚未创建的 App 影响现有项目。

根目录的 `.git` 保留整个集合的 Git 元数据。各 App 目录内不再创建嵌套 Git 仓库。

## 目录更名与编辑器

实际集合目录已更名为 `ios6-apps`。旧目录的临时符号链接会触发 Codex 文件沙箱的路径限制，因此已移除。已有编辑器或 Codex 项目仍可能保存旧路径；继续开发前，请重新选择 `ios6-apps` 目录。Xcode 使用新目录中的共享 workspace。源码和 Git 元数据都保留在新目录中。
