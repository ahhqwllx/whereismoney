import Foundation
import SwiftData

/// 科目数值模型 —— 某一期记录中某个科目的金额
/// 约定：资产存正数，负债存负数（与 Excel 一致）
@Model
final class Entry {
    @Attribute(.unique) var id: UUID
    /// 金额。资产为正，负债为负
    var value: Double
    /// 关联科目
    var account: Account?
    /// 关联记录
    var record: Record?

    init(value: Double = 0, account: Account? = nil, record: Record? = nil) {
        self.id = UUID()
        self.value = value
        self.account = account
        self.record = record
    }
}

// MARK: - 便捷访问

extension Entry {
    /// 科目名称（容错处理已删除科目）
    var accountName: String {
        account?.name ?? "已删除科目"
    }

    /// 科目类型
    var accountType: AccountType {
        account?.type ?? .asset
    }

    /// 显示用的绝对值金额
    var absValue: Double {
        abs(value)
    }
}
