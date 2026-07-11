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

/// 主内容视图 —— 底部 TabView
struct ContentView: View {
    @Environment(FinanceViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context

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
