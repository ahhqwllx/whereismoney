import Foundation
import SwiftData

/// 财务记录模型 —— 一期财务快照，对应 Excel 中的一行
@Model
final class Record {
    @Attribute(.unique) var id: UUID
    /// 记录日期
    var date: Date
    /// 该期所有科目的数值
    @Relationship(deleteRule: .cascade, inverse: \Entry.record)
    var entries: [Entry]

    init(date: Date = .now, entries: [Entry] = []) {
        self.id = UUID()
        self.date = date
        self.entries = entries
    }
}

// MARK: - 计算属性（复用 HTML 仪表盘的计算逻辑）

extension Record {
    /// 所有资产类条目
    var assetEntries: [Entry] {
        entries.filter { $0.accountType == .asset }
    }

    /// 所有负债类条目
    var liabilityEntries: [Entry] {
        entries.filter { $0.accountType == .liability }
    }

    /// 总资产 = 该期所有 .asset 类型 entry 的 value 之和
    var totalAssets: Double {
        assetEntries.reduce(0) { $0 + $1.value }
    }

    /// 总负债 = 该期所有 .liability 类型 entry 的 value 之和（负数）
    var totalLiabilities: Double {
        liabilityEntries.reduce(0) { $0 + $1.value }
    }

    /// 净资产 = 总资产 + 总负债
    var netAssets: Double {
        totalAssets + totalLiabilities
    }

    /// 资产负债率 = abs(总负债) / 总资产 × 100%
    /// 若总资产为 0 返回 0
    var debtToAssetRatio: Double {
        guard totalAssets > 0 else { return 0 }
        return abs(totalLiabilities) / totalAssets * 100
    }

    /// 环比变化（绝对金额）= 当期净资产 - 上期净资产
    /// 需要在外部传入上一条记录
    func change(from previous: Record?) -> Double? {
        guard let previous else { return nil }
        return netAssets - previous.netAssets
    }
}

// MARK: - 排序辅助

extension Record {
    /// 按日期升序排列的 FetchDescriptor
    static var chronological: FetchDescriptor<Record> {
        FetchDescriptor(sortBy: [SortDescriptor(\.date, order: .forward)])
    }

    /// 按日期降序排列的 FetchDescriptor
    static var reverseChronological: FetchDescriptor<Record> {
        FetchDescriptor(sortBy: [SortDescriptor(\.date, order: .reverse)])
    }
}
