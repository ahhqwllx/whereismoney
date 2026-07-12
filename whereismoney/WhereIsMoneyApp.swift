import SwiftUI
import SwiftData

/// App 主入口
@main
struct WhereIsMoneyApp: App {
    /// SwiftData 容器配置
    /// 使用 App Group 共享存储，使小组件也能读取数据
    let container: ModelContainer

    @State private var viewModel = FinanceViewModel()

    init() {
        do {
            // 配置 SwiftData：存储到 App Group 共享目录
            // 注意：iCloud 同步需要付费开发者计划，当前暂未启用
            let config = ModelConfiguration(
                url: AppConstants.sharedStoreURL
            )
            container = try ModelContainer(
                for: Account.self, Record.self, Entry.self,
                configurations: config
            )

            // 首次启动时初始化默认科目
            let context = ModelContext(container)
            let accountCount = (try? context.fetch(FetchDescriptor<Account>()))?.count ?? 0
            if accountCount == 0 {
                for account in Account.createDefaults() {
                    context.insert(account)
                }
                try? context.save()
            }
        } catch {
            fatalError("SwiftData 容器初始化失败: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .preferredColorScheme(.dark)
                .tint(AppTheme.netAsset)
                .onAppear {
                    NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(container)
    }
}

/// 主内容视图 —— iPad 用双栏布局，iPhone 用底部 TabView
struct ContentView: View {
    @Environment(FinanceViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        Group {
            if hSizeClass == .regular {
                // iPad：双栏侧边导航布局
                IPadLayout()
            } else {
                // iPhone：底部 TabView
                IPhoneLayout()
            }
        }
        .tint(AppTheme.netAsset)
        .colorScheme(.dark)
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            viewModel.refresh(context: context)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.dataChangedNotification)) { _ in
            viewModel.refresh(context: context)
        }
    }
}

// MARK: - iPhone 布局（底部 TabView）

struct IPhoneLayout: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("仪表盘", systemImage: "chart.line.uptrend.xyaxis")
                }

            RecordsListView()
                .tabItem {
                    Label("记录", systemImage: "list.bullet.rectangle")
                }

            SummaryView()
                .tabItem {
                    Label("汇总", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
    }
}

// MARK: - iPad 布局（左侧边栏导航）

struct IPadLayout: View {
    enum SidebarItem: String, CaseIterable, Identifiable {
        case dashboard = "仪表盘"
        case records = "记录"
        case summary = "汇总"
        case settings = "设置"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "chart.line.uptrend.xyaxis"
            case .records:   return "list.bullet.rectangle"
            case .summary:   return "chart.bar.fill"
            case .settings:  return "gearshape"
            }
        }
    }

    @State private var selectedItem: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            // 左侧边栏
            List(selection: $selectedItem) {
                ForEach(SidebarItem.allCases) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .font(.system(size: 17))
                        .tag(item)
                }
            }
            .navigationTitle("whereismoney")
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
        } detail: {
            // 右侧内容区
            switch selectedItem {
            case .dashboard:
                DashboardView()
            case .records:
                RecordsListView()
            case .summary:
                SummaryView()
            case .settings:
                SettingsView()
            case .none:
                DashboardView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
