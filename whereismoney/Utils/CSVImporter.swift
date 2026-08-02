import Foundation
import SwiftData

/// CSV 导入 —— 从 CSV 文件导入记录
/// 支持与 CSVExporter 导出格式相同的数据，也兼容现有 Excel 导出的 CSV
enum CSVImporter {
    struct ImportResult {
        var recordsImported: Int
        var errors: [String]
    }

    /// CSV 解析结果：包含待确认的新科目和已解析的记录数据
    struct ParsedCSV {
        /// CSV 中出现但 App 里还没有的新科目名称（需要用户确认类型）
        var newAccountNames: [String]
        /// 已解析的记录数据：每条 = (日期, [科目名: 数值])
        var records: [(date: Date, values: [String: Double])]
        var errors: [String]
    }

    /// 第一步：解析 CSV 文本，识别已有科目和新科目，但不写入数据库
    /// - Parameters:
    ///   - csvText: CSV 文本内容
    ///   - existingAccounts: 已有的科目列表
    /// - Returns: 解析结果（含新科目名称，需用户确认类型后再执行第二步）
    static func parse(csvText: String, existingAccounts: [Account]) -> ParsedCSV {
        var newAccountNames: [String] = []
        var records: [(date: Date, [String: Double])] = []
        var errors: [String] = []

        // 去除 BOM
        let cleaned = csvText.hasPrefix("\u{FEFF}") ? String(csvText.dropFirst()) : csvText
        let lines = cleaned.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard let headerLine = lines.first else {
            return ParsedCSV(newAccountNames: [], records: [], errors: ["CSV 文件为空"])
        }

        let header = parseCSVLine(headerLine)
        guard header.first == "日期" else {
            return ParsedCSV(newAccountNames: [], records: [], errors: ["CSV 格式错误：第一列应为「日期」"])
        }

        // 汇总列名称（不是科目，跳过）
        let summaryColumns: Set<String> = ["总资产", "总负债", "净资产", "环比"]

        // 构建已有科目名称集合
        let existingNames = Set(existingAccounts.map { $0.name })

        // 构建科目列索引（跳过日期列和汇总列）
        let accountColumns: [(index: Int, name: String)] = header.enumerated().compactMap { idx, name in
            if idx == 0 || summaryColumns.contains(name) { return nil }
            return (idx, name)
        }

        // 找出新科目
        for (_, name) in accountColumns {
            if !existingNames.contains(name) && !newAccountNames.contains(name) {
                newAccountNames.append(name)
            }
        }

        // 解析数据行
        for line in lines.dropFirst() {
            let columns = parseCSVLine(line)
            guard columns.count >= 1, let dateStr = columns.first else { continue }

            guard let date = parseDate(dateStr) else {
                errors.append("无法解析日期: \(dateStr)")
                continue
            }

            var values: [String: Double] = [:]
            for col in accountColumns {
                guard col.index < columns.count else { continue }
                let valueStr = columns[col.index].trimmingCharacters(in: .whitespaces)
                values[col.name] = Double(valueStr) ?? 0
            }
            records.append((date, values))
        }

        return ParsedCSV(newAccountNames: newAccountNames, records: records, errors: errors)
    }

    /// 第二步：根据解析结果和用户确认的新科目类型，写入数据库
    /// - Parameters:
    ///   - parsed: 第一步的解析结果
    ///   - context: SwiftData ModelContext
    ///   - existingAccounts: 已有的科目列表
    ///   - newAccountTypes: 用户为新科目选择的类型（科目名 → 类型）
    /// - Returns: 导入结果
    static func importParsed(_ parsed: ParsedCSV, into context: ModelContext, existingAccounts: [Account], newAccountTypes: [String: AccountType]) -> ImportResult {
        var result = ImportResult(recordsImported: 0, errors: parsed.errors)

        // 构建科目名称 → Account 映射（含新建的科目）
        var accountMap = Dictionary(existingAccounts.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })

        var nextAssetOrder = (existingAccounts.filter { $0.type == .asset }.map { $0.order }.max() ?? -1) + 1
        var nextLiabOrder = (existingAccounts.filter { $0.type == .liability }.map { $0.order }.max() ?? 99) + 1

        // 创建新科目（默认开启阈值检测，阈值 30000）
        for name in parsed.newAccountNames {
            let type = newAccountTypes[name] ?? .asset
            let order = type == .liability ? nextLiabOrder : nextAssetOrder
            let newAccount = Account(name: name, type: type, order: order, threshold: EventDetector.defaultThreshold)
            context.insert(newAccount)
            accountMap[name] = newAccount
            if type == .liability {
                nextLiabOrder += 1
            } else {
                nextAssetOrder += 1
            }
        }

        // 创建记录
        for (date, values) in parsed.records {
            let record = Record(date: date)
            for (name, value) in values {
                if let account = accountMap[name] {
                    let entry = Entry(value: value, account: account, record: record)
                    record.entries.append(entry)
                }
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
