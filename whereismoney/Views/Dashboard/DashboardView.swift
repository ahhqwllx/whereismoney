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

                        // 净资产趋势图（ECharts）
                        EChartCard(
                            title: "净资产趋势 & 环比变化",
                            subtitle: "折线为净资产，柱状为环比增减，可双指缩放",
                            chartType: .netAsset,
                            data: EChartsData.from(viewModel: viewModel)
                        )

                        // 关键事件
                        EventListCard()

                        // 资产构成堆叠图（ECharts）
                        EChartCard(
                            title: "资产构成变化",
                            subtitle: "各类资产堆叠面积图，可双指缩放",
                            chartType: .assetStack,
                            data: EChartsData.from(viewModel: viewModel)
                        )

                        // 负债构成堆叠图（ECharts）
                        EChartCard(
                            title: "负债构成变化",
                            subtitle: "各类负债堆叠面积图（绝对值），可双指缩放",
                            chartType: .liabStack,
                            data: EChartsData.from(viewModel: viewModel)
                        )

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

/// ECharts 图表卡片 —— 标题 + WebView 图表 + 全屏按钮
struct EChartCard: View {
    let title: String
    let subtitle: String
    let chartType: EChartsWebView.ChartType
    let data: EChartsData

    @State private var showFullscreen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标题栏 + 全屏按钮
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textDim)
                }
                Spacer()
                Button {
                    showFullscreen = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textDim)
                }
            }

            EChartsWebView(chartType: chartType, data: data)
                .frame(height: 260)
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenChartView(title: title, chartType: chartType, data: data) {
                showFullscreen = false
            }
        }
    }
}

/// 全屏横屏图表查看
struct FullscreenChartView: View {
    let title: String
    let chartType: EChartsWebView.ChartType
    let data: EChartsData
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.textDim)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // 横屏全宽图表
                EChartsWebView(chartType: chartType, data: data, fullscreen: true)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
        }
        // 强制横屏显示
        .rotationEffect(.degrees(90))
        .frame(
            width: UIScreen.main.bounds.height,
            height: UIScreen.main.bounds.width
        )
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
