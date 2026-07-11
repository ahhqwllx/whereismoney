import SwiftUI
import Charts

/// 净资产趋势图 —— 折线 + 环比柱状（双 Y 轴）
struct NetAssetChartCard: View {
    @Environment(FinanceViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("净资产趋势 & 环比变化")
                .font(.headline)
                .foregroundStyle(AppTheme.text)

            Text("折线为净资产，柱状为环比增减")
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)

            Chart {
                // 净资产折线
                ForEach(viewModel.netAssetPoints) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("净资产", point.netAssets)
                    )
                    .foregroundStyle(AppTheme.netAsset)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("日期", point.date),
                        y: .value("净资产", point.netAssets)
                    )
                    .foregroundStyle(
                        .linearGradient(colors: [
                            AppTheme.netAsset.opacity(0.25),
                            AppTheme.netAsset.opacity(0)
                        ], startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)

                    // 环比柱状
                    if let change = point.change {
                        BarMark(
                            x: .value("日期", point.date),
                            y: .value("环比", change)
                        )
                        .foregroundStyle(change >= 0 ? AppTheme.positive.opacity(0.5) : AppTheme.negative.opacity(0.5))
                    }

                    // 点标记
                    PointMark(
                        x: .value("日期", point.date),
                        y: .value("净资产", point.netAssets)
                    )
                    .foregroundStyle(AppTheme.netAsset)
                    .symbolSize(30)
                    .annotation(position: .top, spacing: 4) {
                        if point.date == viewModel.netAssetPoints.last?.date {
                            Text(MoneyFormatter.wan(point.netAssets))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.netAsset)
                        }
                    }
                }
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
            .frame(height: 280)
            .chartPlotStyle {
                $0.background(.clear)
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
