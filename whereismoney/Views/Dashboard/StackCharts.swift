import SwiftUI
import Charts

/// 资产构成堆叠面积图
struct AssetStackChartCard: View {
    @Environment(FinanceViewModel.self) private var viewModel

    var body: some View {
        StackChartCard(
            title: "资产构成变化",
            subtitle: "各类资产堆叠面积图，看配置如何此消彼长",
            points: viewModel.assetStackPoints,
            colors: AppTheme.assetColors
        )
    }
}

/// 负债构成堆叠面积图
struct LiabilityStackChartCard: View {
    @Environment(FinanceViewModel.self) private var viewModel

    var body: some View {
        StackChartCard(
            title: "负债构成变化",
            subtitle: "各类负债堆叠面积图（绝对值）",
            points: viewModel.liabilityStackPoints,
            colors: AppTheme.liabilityColors
        )
    }
}

/// 通用堆叠图卡片 —— 使用 BarMark + position(by:) 实现正确的堆叠
struct StackChartCard: View {
    let title: String
    let subtitle: String
    let points: [FinanceViewModel.StackPoint]
    let colors: [Color]

    /// 扁平化数据：每条数据点 = (日期, 科目名, 科目序号, 数值)
    /// 用于 ForEach 渲染，并通过 .position(by:) 自动堆叠
    private var flatData: [(date: Date, name: String, order: Int, value: Double)] {
        var result: [(date: Date, name: String, order: Int, value: Double)] = []
        for point in points {
            for (idx, item) in point.values.enumerated() {
                result.append((point.date, item.name, idx, item.value))
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.text)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)

            // 图例
            if let firstPoint = points.first {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(firstPoint.values.enumerated()), id: \.offset) { idx, item in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(colors[idx % colors.count])
                                    .frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppTheme.textDim)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Chart(flatData, id: \.name) { item in
                    BarMark(
                        x: .value("日期", item.date),
                        y: .value("金额", item.value)
                    )
                    .position(by: .value("科目", item.order))
                    .foregroundStyle(colors[item.order % colors.count].opacity(0.85))
                    .cornerRadius(2)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(MoneyFormatter.compact(v))
                            }
                        }
                        .foregroundStyle(AppTheme.textDim)
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(AppTheme.border)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(MoneyFormatter.month(date))
                            }
                        }
                        .foregroundStyle(AppTheme.textDim)
                    }
                }
                .chartLegend(.hidden)
                .chartPlotStyle {
                    $0.background(.clear)
                }
                .frame(
                    width: max(CGFloat(points.count) * 50, UIScreen.main.bounds.width - 64),
                    height: 300
                )
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
