import SwiftUI
import Charts

/// 仪表盘主页 —— 对应 HTML 仪表盘
struct DashboardView: View {
    @Environment(FinanceViewModel.self) private var viewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.hasData {
                    LazyVStack(spacing: 16) {
                        // KPI 卡片网格
                        KPICardGrid()

                        // 净资产趋势图 + 事件列表
                        NetAssetChartCard()

                        // 关键事件
                        EventListCard()

                        // 资产构成堆叠图
                        AssetStackChartCard()

                        // 负债构成堆叠图
                        LiabilityStackChartCard()

                        // 最新配置饼图
                        AllocationPieCard(
                            title: "最新资产配置",
                            slices: viewModel.latestAssetPie,
                            colors: AppTheme.assetColors,
                            totalLabel: MoneyFormatter.money(viewModel.kpi?.totalAsset)
                        )

                        AllocationPieCard(
                            title: "最新负债构成",
                            slices: viewModel.latestLiabilityPie,
                            colors: AppTheme.liabilityColors,
                            totalLabel: MoneyFormatter.money(viewModel.kpi?.totalLiab)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                } else {
                    EmptyStateView()
                        .padding(.top, 100)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle("财务仪表盘")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh(context: context)
            }
        }
    }
}

// MARK: - 空状态

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.textDim)

            Text("还没有财务数据")
                .font(.headline)
                .foregroundStyle(AppTheme.text)

            Text("点击「记录」标签，添加你的第一条财务记录")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textDim)
                .multilineTextAlignment(.center)
        }
    }
}
