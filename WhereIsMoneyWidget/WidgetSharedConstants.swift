import Foundation

/// Widget 共享常量 —— 与主 App 的 AppConstants 保持一致
/// 此文件仅用于 Widget Extension 编译，不参与主 App 编译
/// 主 App 的 Account.swift / Record.swift / Entry.swift 会被添加到 Widget target
/// （在 Xcode 文件检查器的 Target Membership 中勾选 WhereIsMoneyWidget）
enum WidgetAppConstants {
    static let appGroup = "group.com.yuqingfang.whereismoney.shared"
    static let storeFileName = "whereismoney.store"

    static var sharedStoreURL: URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        ) else {
            return FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(storeFileName)
        }
        return containerURL.appendingPathComponent(storeFileName)
    }
}

/// 为 Widget Provider 提供 AppConstants.sharedStoreURL 的别名
/// 这样 Widget 代码可以直接引用 AppConstants（与主 App 代码一致）
typealias AppConstants = WidgetAppConstants
