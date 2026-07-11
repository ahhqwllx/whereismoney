# FinanceApp — 个人财务分析 iOS App

基于 HTML 仪表盘的财务分析维度，使用 SwiftUI 原生开发的 iOS 个人财务管理 App。

## 功能特性

### 📊 仪表盘
- 4 个 KPI 卡片：净资产、总资产、总负债、资产负债率（含首期对比）
- 净资产趋势折线图 + 环比柱状图（双 Y 轴）
- 资产构成堆叠面积图、负债构成堆叠面积图
- 最新资产/负债配置环形饼图
- 关键事件自动检测（大额变动、贷款结清）

### 📝 记录管理
- 按日期倒序列出所有记录
- 分组表单录入（资产/负债分组，数字键盘）
- 实时计算净资产、总资产、总负债、负债率
- 记录详情页查看单期全部科目

### 📈 周期汇总
- 按月度/季度/年度聚合
- 净资产均值、期内变化、资产增长率
- 月度净资产变化柱状图

### ⚙️ 增强功能
- **主屏小组件**：systemSmall / systemMedium 两种尺寸，显示最新净资产和环比
- **定期提醒**：可配置每周固定时间推送录入提醒
- **大额变动推送**：净资产环比超阈值时推送通知
- **CSV 导入导出**：与 Excel 互通
- **可自定义科目**：增删改 + 排序 + 阈值设置

## 技术栈

| 技术 | 用途 |
|------|------|
| Swift 5.9 + SwiftUI | UI 框架 |
| SwiftData | 本地数据持久化 |
| CloudKit (iCloud) | 多设备同步（需手动启用） |
| Swift Charts | 折线图、柱状图、面积图 |
| Canvas | 环形饼图（Swift Charts 不支持） |
| WidgetKit | 主屏小组件 |
| UserNotifications | 定期提醒 + 异常推送 |

**最低系统**：iOS 17.0

## 快速开始

### 1. 安装 Xcode

如果尚未安装 Xcode，从 App Store 下载安装：
```
https://apps.apple.com/app/xcode/id497799835
```

安装后，确保命令行工具指向 Xcode（而非 Command Line Tools）：
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### 2. 打开项目

```bash
cd /Users/liuxiao/Documents/code/财务分析/FinanceApp
open FinanceApp.xcodeproj
```

### 3. 配置签名

在 Xcode 中：
1. 选择 `FinanceApp` target → Signing & Capabilities
2. 勾选 Automatically manage signing
3. Team 选择你的开发者账号
4. Bundle Identifier 改成你自己的（如 `com.yourname.financeapp`）

对 `FinanceWidget` target 重复上述步骤。

### 4. 运行

- 选择模拟器或真机
- 按 `Cmd + R` 构建运行

## 项目结构

```
FinanceApp/
├── project.yml                    # XcodeGen 配置文件
├── FinanceApp.xcodeproj           # Xcode 项目（由 XcodeGen 生成）
├── FinanceApp/                    # 主 App
│   ├── FinanceAppApp.swift        # App 入口
│   ├── Models/                    # SwiftData 数据模型
│   │   ├── Account.swift          # 科目（可自定义）
│   │   ├── Record.swift           # 财务记录
│   │   └── Entry.swift            # 科目数值
│   ├── Views/
│   │   ├── Dashboard/             # 仪表盘（KPI + 图表 + 事件）
│   │   ├── Records/               # 记录列表 + 录入 + 详情
│   │   ├── Summary/               # 周期汇总
│   │   ├── Accounts/              # 科目管理
│   │   └── Settings/              # 设置
│   ├── ViewModels/
│   │   └── FinanceViewModel.swift # 数据聚合逻辑
│   ├── Utils/                     # 工具（格式化、事件检测、通知、CSV）
│   ├── Theme/
│   │   └── AppTheme.swift         # 配色常量
│   ├── Assets.xcassets            # 图标/颜色资源
│   └── Info.plist
├── FinanceWidget/                 # 小组件 Extension
│   ├── FinanceWidget.swift        # Widget 入口 + 视图
│   └── WidgetSharedConstants.swift
└── README.md
```

## 启用 iCloud 同步（可选）

App 默认使用本地 SwiftData 存储。如需多设备同步：

1. 在 [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list) 创建 iCloud Container
2. Xcode 中选择 FinanceApp target → Signing & Capabilities → + Capability
3. 添加 **iCloud**，勾选 **CloudKit**
4. 添加你创建的 iCloud Container
5. 修改 `FinanceAppApp.swift` 中的 `ModelConfiguration`，添加 CloudKit 配置：
   ```swift
   let config = ModelConfiguration(
       url: AppConstants.sharedStoreURL,
       cloudKitDatabase: .private(AppConstants.cloudKitContainer)
   )
   ```

## 启用小组件数据共享

小组件需要读取主 App 的数据，需配置 App Group：

1. Xcode 中选择 FinanceApp target → Signing & Capabilities → + Capability
2. 添加 **App Groups**，创建 `group.com.financeapp.shared`
3. 对 FinanceWidget target 重复上述步骤，勾选同一个 App Group
4. 两个 target 的 App Group 必须完全一致

## 重新生成项目文件

如果修改了 `project.yml` 或增删了源文件，用 XcodeGen 重新生成：

```bash
# 安装 XcodeGen（如未安装）
brew install xcodegen

# 重新生成
cd /Users/liuxiao/Documents/code/财务分析/FinanceApp
xcodegen generate
```

## 计算逻辑说明

与 HTML 仪表盘完全一致：

| 指标 | 公式 |
|------|------|
| 总资产 | 该期所有资产类科目之和 |
| 总负债 | 该期所有负债类科目之和（负数） |
| 净资产 | 总资产 + 总负债 |
| 资产负债率 | abs(总负债) / 总资产 × 100% |
| 环比 | 当期净资产 - 上期净资产（绝对金额） |

**约定**：资产存正数，负债存负数（与 Excel 一致）。录入界面中负债输入正数，保存时自动取负。

## 事件检测规则

对设置了 threshold（阈值）的科目，在相邻两期记录间检测：
- 变化绝对值 ≥ 阈值 → 标记为增长/下降事件
- 从非零变为零 → 标记为结清事件

默认阈值：
- ESOP：¥10,000
- 借款：¥5,000
- 其他科目：无（可在科目管理中设置）

## 数据导入导出

### 导出
设置 → 数据管理 → 导出 CSV，生成与 Excel 兼容的 CSV 文件（含 BOM 头）。

### 导入
设置 → 数据管理 → 导入 CSV，选择 CSV 文件导入。格式与导出格式一致：
```
日期,招行余额,ESOP,...,总资产,总负债,净资产,环比
2026-03-16,12451,275000,...,475077,-1038631,-563554,
```

## 首次使用

1. 打开 App，会自动创建 14 个默认科目（9 资产 + 5 负债）
2. 点击「记录」标签 → 右上角「+」新增第一条记录
3. 输入各科目金额，顶部实时显示净资产
4. 保存后切换到「仪表盘」标签查看分析图表

## 许可

个人使用。
