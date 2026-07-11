import SwiftUI

/// 关键事件列表 —— 大额变动自动标注
struct EventListCard: View {
    @Environment(FinanceViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关键事件")
                .font(.headline)
                .foregroundStyle(AppTheme.text)

            Text("大额变动自动检测")
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)

            if viewModel.events.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(AppTheme.textDim)
                    Text("期间内无明显大额变动")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textDim)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(viewModel.events) { event in
                    EventRow(event: event)
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
}

/// 单个事件行
private struct EventRow: View {
    let event: FinanceEvent

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 左侧色条
            RoundedRectangle(cornerRadius: 1.5)
                .fill(eventColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.dateText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.warning)

                Text(event.description)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.text)
            }
            Spacer()
        }
        .padding(10)
        .background(AppTheme.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var eventColor: Color {
        switch event.type {
        case .increase: return AppTheme.positive
        case .decrease: return AppTheme.negative
        case .cleared:  return AppTheme.warning
        }
    }
}
