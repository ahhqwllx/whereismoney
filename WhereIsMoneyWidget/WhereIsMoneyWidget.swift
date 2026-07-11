import WidgetKit
import SwiftUI
import SwiftData

/// 主屏小组件 —— 显示最新净资产 + 环比变化
struct FinanceWidget: Widget {
    let kind: String = "FinanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FinanceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("财务概览")
        .description("在主屏快速查看最新净资产和环比变化")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 数据提供者

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now, netAssets: -394243, change: -4771, dateText: "2026-07-05")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(loadLatestEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = loadLatestEntry()
        // 每小时刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// 从共享 SwiftData 存储中读取最新记录
    private func loadLatestEntry() -> SimpleEntry {
        do {
            let config = ModelConfiguration(url: AppConstants.sharedStoreURL)
            let container = try ModelContainer(
                for: Record.self, Account.self, Entry.self,
                configurations: config
            )
            let context = ModelContext(container)
            let records = (try? context.fetch(Record.reverseChronological)) ?? []

            guard records.count >= 1 else {
                return SimpleEntry(date: .now, netAssets: nil, change: nil, dateText: "暂无数据")
            }

            let latest = records[0]
            let change: Double? = records.count >= 2
                ? latest.netAssets - records[1].netAssets
                : nil

            return SimpleEntry(
                date: .now,
                netAssets: latest.netAssets,
                change: change,
                dateText: WidgetDateFormatter.string(from: latest.date)
            )
        } catch {
            return SimpleEntry(date: .now, netAssets: nil, change: nil, dateText: "读取失败")
        }
    }
}

// MARK: - 数据模型

struct SimpleEntry: TimelineEntry {
    let date: Date
    let netAssets: Double?
    let change: Double?
    let dateText: String
}

// MARK: - 小组件视图

struct FinanceWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                Text("净资产")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatMoney(entry.netAssets))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(entry.netAssets.map { $0 >= 0 ? .green : .red } ?? .secondary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            if let change = entry.change {
                Text(formatChange(change))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(change >= 0 ? .green : .red)
            }

            Spacer()

            Text(entry.dateText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            // 左侧：净资产
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                    Text("净资产")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formatMoney(entry.netAssets))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.netAssets.map { $0 >= 0 ? .green : .red } ?? .secondary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(entry.dateText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右侧：环比
            VStack(alignment: .trailing, spacing: 4) {
                Text("环比变化")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                if let change = entry.change {
                    Text(formatChange(change))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(change >= 0 ? .green : .red)

                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 24))
                        .foregroundStyle(change >= 0 ? .green : .red)
                } else {
                    Text("—")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 格式化

    private func formatMoney(_ value: Double?) -> String {
        guard let value else { return "—" }
        let sign = value < 0 ? "-" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        let absStr = formatter.string(from: NSNumber(value: abs(value))) ?? "0"
        return "\(sign)¥\(absStr)"
    }

    private func formatChange(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : "-"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        let absStr = formatter.string(from: NSNumber(value: abs(value))) ?? "0"
        return "\(sign)¥\(absStr)"
    }
}

// MARK: - 日期格式化（Widget 内独立使用，避免依赖主 App）

enum WidgetDateFormatter {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }
}
