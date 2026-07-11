import SwiftUI

/// 配置饼图卡片 —— 使用 Canvas 绘制环形图
/// Swift Charts 在 iOS 17 对饼图支持有限，故用自定义 View 实现
struct AllocationPieCard: View {
    let title: String
    let slices: [FinanceViewModel.PieSlice]
    let colors: [Color]
    let totalLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.text)

            Text("合计 \(totalLabel)")
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)

            if slices.isEmpty {
                Spacer()
                Text("暂无数据")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textDim)
                Spacer()
            } else {
                DonutChart(slices: slices, colors: colors)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)

                // 图例列表
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(slices) { slice in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colors[slice.colorIndex % colors.count])
                                .frame(width: 8, height: 8)
                            Text(slice.name)
                                .font(.system(size: 10))
                                .foregroundStyle(AppTheme.textDim)
                            Spacer()
                            Text(percentText(slice))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppTheme.text)
                        }
                    }
                }
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

    private func percentText(_ slice: FinanceViewModel.PieSlice) -> String {
        let total = slices.reduce(0) { $0 + $1.value }
        guard total > 0 else { return "0%" }
        return String(format: "%.1f%%", slice.value / total * 100)
    }
}

/// 环形图（Donut Chart）—— 使用 Canvas 绘制
struct DonutChart: View {
    let slices: [FinanceViewModel.PieSlice]
    let colors: [Color]

    var body: some View {
        Canvas { context, size in
            let total = slices.reduce(0) { $0 + $1.value }
            guard total > 0 else { return }

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4
            let innerRadius = radius * 0.6

            var startAngle = Angle.degrees(-90)

            for slice in slices {
                let angle = Angle.degrees(slice.value / total * 360)
                let endAngle = startAngle + angle

                let path = Path { p in
                    // 外弧
                    p.addArc(center: center, radius: radius,
                             startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    // 内弧（反向）
                    p.addArc(center: center, radius: innerRadius,
                             startAngle: endAngle, endAngle: startAngle, clockwise: true)
                    p.closeSubpath()
                }

                context.fill(path, with: .color(colors[slice.colorIndex % colors.count]))

                startAngle = endAngle
            }

            // 中心文字：合计
            let totalText = MoneyFormatter.compact(total)
            context.draw(
                Text(totalText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.text),
                at: center
            )
        }
    }
}
