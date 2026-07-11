import SwiftUI

/// KPI 卡片网格 —— 2×2 布局
struct KPICardGrid: View {
    @Environment(FinanceViewModel.self) private var viewModel

    var body: some View {
        let kpi = viewModel.kpi
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            KPICard(
                label: "净资产",
                value: MoneyFormatter.money(kpi?.netLatest),
                accentColor: AppTheme.netAsset,
                subText: subTextForNet(kpi),
                deltaText: deltaTextForNet(kpi),
                deltaColor: (kpi?.netDelta ?? 0) >= 0 ? AppTheme.positive : AppTheme.negative
            )

            KPICard(
                label: "资产负债率",
                value: MoneyFormatter.percent(kpi?.ratioLatest),
                accentColor: AppTheme.warning,
                subText: "首期 \(MoneyFormatter.percent(kpi?.ratioFirst))",
                deltaText: kpi.map { MoneyFormatter.pctChange($0.ratioLatest - $0.ratioFirst) },
                deltaColor: (kpi.map { $0.ratioLatest - $0.ratioFirst } ?? 0) >= 0
                    ? AppTheme.negative  // 负债率上升 = 负面
                    : AppTheme.positive   // 负债率下降 = 正面
            )

            KPICard(
                label: "总资产",
                value: MoneyFormatter.money(kpi?.totalAsset),
                accentColor: AppTheme.summary,
                subText: "资产类合计"
            )

            KPICard(
                label: "总负债",
                value: MoneyFormatter.money(kpi?.totalLiab),
                accentColor: AppTheme.danger,
                subText: "负债类合计"
            )
        }
    }

    private func subTextForNet(_ kpi: FinanceViewModel.KPIData?) -> String {
        guard let kpi else { return "" }
        return "最高 \(MoneyFormatter.money(kpi.netMax))\n最低 \(MoneyFormatter.money(kpi.netMin))"
    }

    private func deltaTextForNet(_ kpi: FinanceViewModel.KPIData?) -> String? {
        guard let kpi else { return nil }
        return "首期 \(MoneyFormatter.money(kpi.netFirst)) → 期末 \(MoneyFormatter.money(kpi.netLatest))"
    }
}

/// 单个 KPI 卡片
struct KPICard: View {
    let label: String
    let value: String
    let accentColor: Color
    var subText: String? = nil
    var deltaText: String? = nil
    var deltaColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.text)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let subText {
                Text(subText)
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.textDim)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let deltaText, let deltaColor {
                Text(deltaText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(deltaColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if subText == nil {
                // 占位，保证无 deltaText 时高度一致
                Color.clear.frame(height: 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(AppTheme.card)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(accentColor)
                .frame(width: 3)
                .padding(.vertical, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
