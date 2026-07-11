import Foundation

/// App 全局常量
enum AppConstants {
    /// App Group 标识（用于主 App 与小组件共享数据）
    /// ⚠️ 需在 Xcode 的 Signing & Capabilities 中添加同名 App Group
    static let appGroup = "group.com.financeapp.shared"

    /// SwiftData 共享存储文件名
    static let storeFileName = "FinanceApp.store"

    /// 共享 SwiftData 容器的 URL
    static var sharedStoreURL: URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        ) else {
            // 降级到普通 Documents 目录
            return FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(storeFileName)
        }
        return containerURL.appendingPathComponent(storeFileName)
    }

    /// iCloud 容器标识
    /// ⚠️ 需在 Apple Developer Portal 创建并在 Xcode 中启用 CloudKit
    static let cloudKitContainer = "iCloud.com.financeapp"

    /// 默认大额变动提醒阈值（净资产环比变化超过此值时推送）
    static let defaultAnomalyThreshold: Double = 50_000

    /// UserDefaults 键
    enum UserDefaultsKey {
        static let reminderEnabled     = "reminderEnabled"
        static let reminderWeekday     = "reminderWeekday"     // 1-7
        static let reminderHour        = "reminderHour"
        static let reminderMinute      = "reminderMinute"
        static let anomalyThreshold    = "anomalyThreshold"
        static let hasCompletedOnboard = "hasCompletedOnboard"
    }

    /// 数据变更通知名（记录增删改后发送，触发仪表盘刷新）
    static let dataChangedNotification = Notification.Name("FinanceAppDataChanged")
}
