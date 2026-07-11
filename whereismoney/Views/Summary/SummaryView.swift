import SwiftUI
import SwiftData
import Charts

/// 周期汇总页 —— 按月/季/年聚合数据
struct SummaryView: View {
    @Query(Record.chronological) private var records: [Record]

    @State private var period: Period = .month

    enum Period: String, CaseIterable, Identifiable {
        case month = "月度"
        case quarter = "季度"
        case year = "年度"
        var id: String { rawValue }
    }

    /// 按周期分组后的汇总数据
    private var summaries: [PeriodSummary] {
        let groups = Dictionary(grouping: records) { record -> String in
            switch period {
            case .month:
                return MoneyFormatter.month(record.date)
            case .quarter:
                let cal = Calendar(identifier: .gregorian)
                let q = (cal.component(.month, from: record.date) - 1) / 3 + 1
                return "\(cal.component(.year, from: record.date)) Q\(q)"
            case .year:
                let cal = Calendar(identifier: .gregorian)
                return String(cal.component(.year, from: record.date))
            }
        }
        return groups.map { (key, recs) in
            PeriodSummary(
                label: key,
                records: recs.sorted { $0.date < $1.date },
                netAssets: recs.map { $0.netAssets }.reduce(0, +) / Double(recs.count),
                startNet: recs.sorted { $0.date < $1.date }.first?.netAssets ?? 0,
                endNet: recs.sorted { $0.date < $1.date }.last?.netAssets ?? 0,
                avgTotalAssets: recs.map { $0.totalAssets }.reduce(0, +) / Double(recs.count),
                avgTotalLiabilities: recs.map { $0.totalLiabilities }.reduce(0, +) / Double(recs.count),
                recordCount: recs.count
            )
        }
        .sorted { $0.label < $1.label }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if records.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(AppTheme.textDim)
                        Text("暂无数据")
                            .foregroundStyle(AppTheme.textDim)
                    }
                    .padding(.top, 100)
                } else {
                    VStack(spacing: 16) {
                        // 周期选择器
                        Picker("周期", selection: $period) {
                            ForEach(Period.allCases) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)

                        // 净资产变化柱状图
                        netAssetChangeChart

                        // 周期对比列表
                        ForEach(summaries) { summary in
                            PeriodSummaryCard(summary: summary)
                        }
                    }
                    .padding(16)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("周期汇总")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - 净资产变化柱状图

    private var netAssetChangeChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("各\(period.rawValue)净资产均值")
                .font(.headline)
                .foregroundStyle(AppTheme.text)

            Text("柱状显示每个周期的平均净资产")
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)

            Chart {
                ForEach(summaries) { summary in
                    BarMark(
                        x: .value("周期", summary.label),
                        y: .value("净资产", summary.netAssets)
                    )
                    .foregroundStyle(summary.netAssets >= 0 ? AppTheme.netAsset : AppTheme.negative)
                    .cornerRadius(4)
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
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textDim)
                }
            }
            .frame(height: 200)
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

// MARK: - 数据模型

struct PeriodSummary: Identifiable {
    let id = UUID()
    let label: String
    let records: [Record]
    let netAssets: Double       // 净资产均值
    let startNet: Double        // 周期起始净资产
    let endNet: Double          // 周期结束净资产
    let avgTotalAssets: Double
    let avgTotalLiabilities: Double
    let recordCount: Int

    /// 周期内净资产变化
    var netChange: Double { endNet - startNet }

    /// 资产增长率
    var assetGrowthRate: Double {
        guard avgTotalLiabilities != 0 else { return 0 }
        return netChange / abs(avgTotalLiabilities) * 100
    }
}

// MARK: - 周期汇总卡片

private struct PeriodSummaryCard: View {
    let summary: PeriodSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 周期标题
            HStack {
                Text(summary.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("\(summary.recordCount) 期")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textDim)
            }

            // 净资产均值
            HStack {
                Text("净资产均值")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textDim)
                Spacer()
                Text(MoneyFormatter.money(summary.netAssets))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.netAsset)
            }

            // 变化指标
            HStack(spacing: 8) {
                metricItem(label: "期内变化", value: summary.netChange, color: summary.netChange >= 0 ? AppTheme.positive : AppTheme.negative, isSigned: true)
                metricItem(label: "期初净资产", value: summary.startNet, color: AppTheme.text)
                metricItem(label: "期末净资产", value: summary.endNet, color: AppTheme.text)
            }

            // 资产/负债均值 —— 资产均值左对齐，负债均值右对齐，整体更协调
            HStack(spacing: 8) {
                metricItem(label: "资产均值", value: summary.avgTotalAssets, color: AppTheme.asset, alignment: .leading)
                metricItem(label: "负债均值", value: summary.avgTotalLiabilities, color: AppTheme.liability, alignment: .trailing)
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

    private func metricItem(label: String, value: Double, color: Color, isSigned: Bool = false, alignment: Alignment = .leading) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.textDim)
            Text(isSigned ? MoneyFormatter.signedMoney(value) : MoneyFormatter.money(value))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: alignment)
    }
}
