import Foundation
import UserNotifications

/// 通知管理 —— 定期录入提醒 + 大额变动异常推送
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // MARK: - 通知标识
    enum Identifier: String {
        case reminder      = "com.whereismoney.reminder"
        case anomaly       = "com.whereismoney.anomaly"
    }

    // MARK: - 权限请求

    /// 请求通知权限（首次启动时调用）
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("✅ 通知权限已授予")
            } else {
                print("⚠️ 通知权限被拒绝")
            }
        }
    }

    // MARK: - 定期录入提醒

    /// 设置定期录入提醒
    /// - Parameters:
    ///   - weekday: 周几（1=周日, 2=周一, ... 7=周六）
    ///   - hour: 小时（24小时制）
    ///   - minute: 分钟
    func scheduleReminder(weekday: Int, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()

        // 先移除旧的提醒
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.reminder.rawValue])

        let content = UNMutableNotificationContent()
        content.title = "该记录财务数据了 📊"
        content.body = "点击打开 App，录入本周的资产和负债情况"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.reminder.rawValue,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("❌ 设置提醒失败: \(error)")
            } else {
                print("✅ 已设置定期提醒: 周\(weekday) \(hour):\(String(format: "%02d", minute))")
            }
        }
    }

    /// 取消定期提醒
    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Identifier.reminder.rawValue]
        )
        print("✅ 已取消定期提醒")
    }

    // MARK: - 大额变动推送

    /// 检查并发送大额变动通知
    /// - Parameter change: 净资产环比变化金额
    /// - Parameter threshold: 阈值（默认 5 万）
    func checkAnomaly(netAssetChange change: Double?, threshold: Double = 50_000) {
        guard let change, abs(change) >= threshold else { return }

        let content = UNMutableNotificationContent()
        let isIncrease = change > 0
        content.title = isIncrease ? "净资产大幅增长 📈" : "净资产大幅下降 📉"
        content.body = "本期净资产变化 \(MoneyFormatter.signedMoney(change))，已超过阈值 \(MoneyFormatter.money(threshold))"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(Identifier.anomaly.rawValue).\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("❌ 发送异常通知失败: \(error)")
            }
        }
    }

    // MARK: - 查询

    /// 获取当前待处理的通知
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
}
