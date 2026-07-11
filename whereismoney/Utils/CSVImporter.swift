import Foundation
import SwiftData

/// CSV 导入 —— 从 CSV 文件导入记录
/// 支持与 CSVExporter 导出格式相同的数据，也兼容现有 Excel 导出的 CSV
enum CSVImporter {
    struct ImportResult {
        var recordsImported: Int
        var errors: [String]
    }

    /// 解析 CSV 文本并导入到 ModelContext
    /// - Parameters:
    ///   - csvText: CSV 文本内容
    ///   - context: SwiftData ModelContext
    ///   - existingAccounts: 已有的科目列表（按名称匹配）
    /// - Returns: 导入结果
    static func `import`(csvText: String, into context: ModelContext, existingAccounts: [Account]) -> ImportResult {
        var result = ImportResult(recordsImported: 0, errors: [])

        // 去除 BOM
        let cleaned = csvText.hasPrefix("\u{FEFF}") ? String(csvText.dropFirst()) : csvText
        let lines = cleaned.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard let headerLine = lines.first else {
            result.errors.append("CSV 文件为空")
            return result
        }

        let header = parseCSVLine(headerLine)
        guard header.first == "日期" else {
            result.errors.append("CSV 格式错误：第一列应为「日期」")
            return result
        }

        // 构建科目名称 → Account 映射
        let accountMap = Dictionary(existingAccounts.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })

        // 构建列索引
        let accountColumns: [(index: Int, account: Account)] = header.enumerated().compactMap { idx, name in
            if let acc = accountMap[name] {
                return (idx, acc)
            }
            return nil
        }

        // 解析数据行
        for line in lines.dropFirst() {
            let columns = parseCSVLine(line)
            guard columns.count >= 1, let dateStr = columns.first else { continue }

            // 解析日期
            guard let date = parseDate(dateStr) else {
                result.errors.append("无法解析日期: \(dateStr)")
                continue
            }

            // 创建记录
            let record = Record(date: date)

            // 解析各科目数值
            for col in accountColumns {
                guard col.index < columns.count else { continue }
                let valueStr = columns[col.index].trimmingCharacters(in: .whitespaces)
                let value = Double(valueStr) ?? 0
                let entry = Entry(value: value, account: col.account, record: record)
                record.entries.append(entry)
            }

            context.insert(record)
            result.recordsImported += 1
        }

        return result
    }

    // MARK: - 私有方法

    /// 解析单行 CSV（支持带引号的字段）
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)

        return fields.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// 解析日期（支持 yyyy-MM-dd 和 yyyy/MM/dd）
    private static func parseDate(_ str: String) -> Date? {
        let formats = ["yyyy-MM-dd", "yyyy/MM/dd", "yyyy-MM-dd HH:mm:ss"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: str) {
                return date
            }
        }
        return nil
    }
}
