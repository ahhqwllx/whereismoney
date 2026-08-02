import Foundation
import SwiftData

/// 科目类型
enum AccountType: String, Codable, CaseIterable, Identifiable {
    case asset     // 资产
    case liability // 负债

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .asset:     return "资产"
        case .liability: return "负债"
        }
    }
}

/// 科目模型 —— 用户可自定义增删改的财务科目（如"招行余额"、"房贷-商贷"）
@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: AccountType
    /// 排列顺序，数值越小越靠前
    var order: Int
    /// 大额变动提醒阈值（可选），用于事件检测；为 nil 时不检测
    var threshold: Double?
    var createdAt: Date

    /// 该科目下的所有录入值（反向关系）
    @Relationship(deleteRule: .nullify, inverse: \Entry.account)
    var entries: [Entry]

    init(name: String, type: AccountType, order: Int, threshold: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.order = order
        self.threshold = threshold
        self.createdAt = .now
        self.entries = []
    }
}

// MARK: - 预置科目

extension Account {
    /// 与现有 Excel 一致的默认科目（7 资产 + 4 负债）
    /// 所有科目默认开启阈值检测（30000）
    static let defaultAccounts: [(name: String, type: AccountType, threshold: Double?)] = [
        // 资产
        ("招行余额",     .asset, 30_000),
        ("工商银行",     .asset, 30_000),
        ("支付宝余额",   .asset, 30_000),
        ("微信余额",     .asset, 30_000),
        ("小荷包",       .asset, 30_000),
        ("美股",         .asset, 30_000),
        ("现金",         .asset, 30_000),
        // 负债
        ("招行负债",       .liability, 30_000),
        ("房贷-商贷",     .liability, 30_000),
        ("房贷-公积金贷", .liability, 30_000),
        ("车贷",           .liability, 30_000),
    ]

    /// 生成预置科目的便捷方法
    static func createDefaults() -> [Account] {
        defaultAccounts.enumerated().map { index, item in
            Account(name: item.name, type: item.type, order: index, threshold: item.threshold)
        }
    }
}
