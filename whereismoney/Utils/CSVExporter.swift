import Foundation

/// CSV 导出 —— 将所有记录导出为 CSV，便于与 Excel 互通
/// 输出格式与现有 财务状况.xlsx 的列顺序一致
enum CSVExporter {
    /// 导出全部记录为 CSV 字符串
    /// - Parameters:
    ///   - records: 按日期升序排列的记录
    ///   - accounts: 所有科目（决定列顺序）
    /// - Returns: CSV 文本
    static func export(records: [Record], accounts: [Account]) -> String {
        let sortedRecords = records.sorted { $0.date < $1.date }
        let sortedAccounts = accounts.sorted { $0.order < $1.order }

        // 表头：日期 + 各科目 + 总资产 + 总负债 + 净资产 + 环比
        var header = ["日期"]
        header.append(contentsOf: sortedAccounts.map { $0.name })
        header.append(contentsOf: ["总资产", "总负债", "净资产", "环比"])

        var lines: [String] = [header.joined(separator: ",")]

        // 数据行
        for (i, record) in sortedRecords.enumerated() {
            var row: [String] = []
            row.append(MoneyFormatter.date(record.date))

            // 各科目数值
            let entryMap = Dictionary(record.entries.compactMap { e -> (UUID, Double)? in
                guard let acc = e.account else { return nil }
                return (acc.id, e.value)
            }, uniquingKeysWith: { a, _ in a })

            for account in sortedAccounts {
                let value = entryMap[account.id] ?? 0
                row.append(String(format: "%.2f", value))
            }

            // 汇总列
            row.append(String(format: "%.2f", record.totalAssets))
            row.append(String(format: "%.2f", record.totalLiabilities))
            row.append(String(format: "%.2f", record.netAssets))

            // 环比
            if i > 0 {
                let prev = sortedRecords[i - 1]
                let change = record.netAssets - prev.netAssets
                row.append(String(format: "%.2f", change))
            } else {
                row.append("")
            }

            lines.append(row.joined(separator: ","))
        }

        // BOM 头确保 Excel 正确识别 UTF-8
        return "\u{FEFF}" + lines.joined(separator: "\n")
    }

    /// 导出为临时文件，返回文件 URL
    static func exportToFile(records: [Record], accounts: [Account]) -> URL {
        let csv = export(records: records, accounts: accounts)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("财务状况_\(MoneyFormatter.date(.now)).csv")
        try? csv.data(using: .utf8)?.write(to: tempURL)
        return tempURL
    }
}
