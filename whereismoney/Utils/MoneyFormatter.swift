import Foundation

/// 金额格式化工具 —— 复用 HTML 仪表盘的格式化逻辑
enum MoneyFormatter {
    /// 标准金额格式：¥123,456 / -¥123,456（千分位，无小数）
    static func money(_ value: Double?) -> String {
        guard let value else { return "—" }
        let sign = value < 0 ? "-" : ""
        let absVal = abs(value)
        let formatted = numberFormatter.string(from: NSNumber(value: absVal)) ?? "0"
        return "\(sign)¥\(formatted)"
    }

    /// 带正负号的金额（环比用）：+¥1,234 / -¥1,234
    static func signedMoney(_ value: Double?) -> String {
        guard let value else { return "—" }
        let sign = value >= 0 ? "+" : "-"
        let absVal = abs(value)
        let formatted = numberFormatter.string(from: NSNumber(value: absVal)) ?? "0"
        return "\(sign)¥\(formatted)"
    }

    /// 万元单位：12.3万
    static func wan(_ value: Double?) -> String {
        guard let value else { return "—" }
        let wan = value / 10_000
        return String(format: "%.1f万", wan)
    }

    /// 百分比：141.0%
    static func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f%%", value)
    }

    /// 百分点变化（带箭头）：▼ 77.6 pct
    static func pctChange(_ delta: Double) -> String {
        let arrow = delta >= 0 ? "▲" : "▼"
        return "\(arrow) \(String(format: "%.1f", abs(delta))) pct"
    }

    /// 紧凑金额（图表坐标轴用）：12.3万 / 5.6k
    static func compact(_ value: Double) -> String {
        let absVal = abs(value)
        if absVal >= 10_000 {
            return String(format: "%.0f万", value / 10_000)
        } else if absVal >= 1_000 {
            return String(format: "%.0fk", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }

    /// 日期格式化：2026-07-05
    static func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// 日期格式化（含星期）：2026-07-05 周六
    static func dateWithWeekday(_ date: Date) -> String {
        dateWeekdayFormatter.string(from: date)
    }

    /// 月份格式化：2026-07
    static func month(_ date: Date) -> String {
        monthFormatter.string(from: date)
    }

    // MARK: - 私有 Formatter

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.maximumFractionDigits = 0
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    private static let dateWeekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd EEE"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()
}
