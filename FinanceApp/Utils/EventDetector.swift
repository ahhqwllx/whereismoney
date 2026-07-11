import Foundation

/// 财务事件 —— 大额变动的自动检测与标注
/// 复用 HTML 仪表盘的事件检测逻辑，并泛化为对所有设置了 threshold 的科目生效
struct FinanceEvent: Identifiable {
    let id = UUID()
    let date: Date
    let accountName: String
    let previousValue: Double
    let currentValue: Double
    let change: Double
    let type: EventType

    enum EventType {
        case increase   // 增长
        case decrease   // 下降
        case cleared    // 归零（如贷款还清）

        var displayName: String {
            switch self {
            case .increase: return "增长"
            case .decrease: return "下降"
            case .cleared:  return "结清"
            }
        }
    }

    /// 变化描述文本
    var description: String {
        switch type {
        case .cleared:
            return "\(accountName)结清（原 \(MoneyFormatter.money(previousValue))）"
        default:
            let sign = change >= 0 ? "+" : ""
            return "\(accountName) \(MoneyFormatter.money(previousValue)) → \(MoneyFormatter.money(currentValue))（\(sign)\(MoneyFormatter.money(change))）"
        }
    }

    /// 日期文本
    var dateText: String {
        MoneyFormatter.date(date)
    }
}

/// 事件检测器
enum EventDetector {
    /// 从按日期升序排列的记录中检测大额变动事件
    /// 逻辑：遍历相邻两期记录，对每个设置了 threshold 的科目比较数值变化
    ///       若变化绝对值超过 threshold，或科目值从非零变为零（结清），则生成事件
    static func detect(from records: [Record]) -> [FinanceEvent] {
        guard records.count >= 2 else { return [] }

        let sorted = records.sorted { $0.date < $1.date }
        var events: [FinanceEvent] = []

        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let curr = sorted[i]

            // 构建上期科目→数值 的映射
            let prevMap = Dictionary(prev.entries.compactMap { e -> (UUID, Double)? in
                guard let acc = e.account else { return nil }
                return (acc.id, e.value)
            }, uniquingKeysWith: { a, _ in a })

            for entry in curr.entries {
                guard let account = entry.account,
                      let threshold = account.threshold else { continue }

                let prevValue = prevMap[account.id] ?? 0
                let currValue = entry.value
                let diff = currValue - prevValue

                // 结清事件：从非零变为零
                if currValue == 0 && prevValue != 0 {
                    events.append(FinanceEvent(
                        date: curr.date,
                        accountName: account.name,
                        previousValue: prevValue,
                        currentValue: currValue,
                        change: diff,
                        type: .cleared
                    ))
                    continue
                }

                // 大额变动事件
                if abs(diff) >= threshold && prevValue != currValue {
                    events.append(FinanceEvent(
                        date: curr.date,
                        accountName: account.name,
                        previousValue: prevValue,
                        currentValue: currValue,
                        change: diff,
                        type: diff > 0 ? .increase : .decrease
                    ))
                }
            }
        }

        // 按日期降序排列
        return events.sorted { $0.date > $1.date }
    }
}
