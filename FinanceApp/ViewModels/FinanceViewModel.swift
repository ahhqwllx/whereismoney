import Foundation
import SwiftUI
import SwiftData
import Observation

/// 财务数据 ViewModel —— 聚合仪表盘所需的 KPI、图表数据、事件
/// 使用 @Observable（iOS 17+）替代 ObservableObject，性能更好
@Observable
final class FinanceViewModel {

    // MARK: - KPI 数据

    struct KPIData {
        let netLatest: Double
        let netFirst: Double
        let netDelta: Double
        let totalAsset: Double
        let totalLiab: Double
        let ratioLatest: Double
        let ratioFirst: Double
        let netMax: Double
        let netMaxDate: Date
        let netMin: Double
        let netMinDate: Date
        let recordCount: Int
        let firstDate: Date
        let latestDate: Date
    }

    // MARK: - 图表数据点

    struct NetAssetPoint: Identifiable {
        let id = UUID()
        let date: Date
        let netAssets: Double
        let change: Double? // 环比
    }

    struct StackPoint: Identifiable {
        let id = UUID()
        let date: Date
        let values: [(name: String, value: Double)] // 各科目数值
        let total: Double
    }

    struct PieSlice: Identifiable {
        let id = UUID()
        let name: String
        let value: Double
        let colorIndex: Int
    }

    // MARK: - 状态

    private(set) var kpi: KPIData?
    private(set) var netAssetPoints: [NetAssetPoint] = []
    private(set) var assetStackPoints: [StackPoint] = []
    private(set) var liabilityStackPoints: [StackPoint] = []
    private(set) var latestAssetPie: [PieSlice] = []
    private(set) var latestLiabilityPie: [PieSlice] = []
    private(set) var events: [FinanceEvent] = []

    /// 是否有数据
    var hasData: Bool {
        !netAssetPoints.isEmpty
    }

    // MARK: - 数据刷新

    /// 从 SwiftData 查询并重新计算所有仪表盘数据
    @MainActor
    func refresh(context: ModelContext) {
        // 获取所有记录（按日期升序）
        let records = (try? context.fetch(Record.chronological)) ?? []
        guard !records.isEmpty else {
            clear()
            return
        }

        // 获取所有科目（按 order 排序）
        let accounts = ((try? context.fetch(FetchDescriptor<Account>(
            sortBy: [SortDescriptor(\.order)]
        ))) ?? []).filter { $0.type == .asset || $0.type == .liability }

        computeKPI(records: records)
        computeNetAssetPoints(records: records)
        computeStackPoints(records: records, accounts: accounts)
        computePieSlices(latestRecord: records.last!, accounts: accounts)
        events = EventDetector.detect(from: records)
    }

    // MARK: - 计算方法

    private func clear() {
        kpi = nil
        netAssetPoints = []
        assetStackPoints = []
        liabilityStackPoints = []
        latestAssetPie = []
        latestLiabilityPie = []
        events = []
    }

    private func computeKPI(records: [Record]) {
        let first = records.first!
        let latest = records.last!

        let netValues = records.map { $0.netAssets }
        let maxIdx = netValues.indices.max(by: { netValues[$0] < netValues[$1] })!
        let minIdx = netValues.indices.min(by: { netValues[$0] < netValues[$1] })!

        let ratioLatest = latest.debtToAssetRatio
        let ratioFirst = first.debtToAssetRatio

        kpi = KPIData(
            netLatest: latest.netAssets,
            netFirst: first.netAssets,
            netDelta: latest.netAssets - first.netAssets,
            totalAsset: latest.totalAssets,
            totalLiab: latest.totalLiabilities,
            ratioLatest: ratioLatest,
            ratioFirst: ratioFirst,
            netMax: netValues[maxIdx],
            netMaxDate: records[maxIdx].date,
            netMin: netValues[minIdx],
            netMinDate: records[minIdx].date,
            recordCount: records.count,
            firstDate: first.date,
            latestDate: latest.date
        )
    }

    private func computeNetAssetPoints(records: [Record]) {
        netAssetPoints = records.enumerated().map { idx, record in
            NetAssetPoint(
                date: record.date,
                netAssets: record.netAssets,
                change: idx > 0 ? record.netAssets - records[idx - 1].netAssets : nil
            )
        }
    }

    private func computeStackPoints(records: [Record], accounts: [Account]) {
        let assetAccounts = accounts.filter { $0.type == .asset }
        let liabilityAccounts = accounts.filter { $0.type == .liability }

        assetStackPoints = records.map { record in
            let values = assetAccounts.map { account -> (name: String, value: Double) in
                let entry = record.entries.first { $0.account?.id == account.id }
                return (account.name, entry?.value ?? 0)
            }
            return StackPoint(
                date: record.date,
                values: values,
                total: values.reduce(0) { $0 + $1.value }
            )
        }

        liabilityStackPoints = records.map { record in
            let values = liabilityAccounts.map { account -> (name: String, value: Double) in
                let entry = record.entries.first { $0.account?.id == account.id }
                return (account.name, abs(entry?.value ?? 0)) // 负债取绝对值
            }
            return StackPoint(
                date: record.date,
                values: values,
                total: values.reduce(0) { $0 + $1.value }
            )
        }
    }

    private func computePieSlices(latestRecord: Record, accounts: [Account]) {
        let assetAccounts = accounts.filter { $0.type == .asset }
        let liabilityAccounts = accounts.filter { $0.type == .liability }

        latestAssetPie = assetAccounts.enumerated().compactMap { idx, account in
            let entry = latestRecord.entries.first { $0.account?.id == account.id }
            let value = entry?.value ?? 0
            guard value > 0 else { return nil }
            return PieSlice(name: account.name, value: value, colorIndex: idx)
        }

        latestLiabilityPie = liabilityAccounts.enumerated().compactMap { idx, account in
            let entry = latestRecord.entries.first { $0.account?.id == account.id }
            let value = abs(entry?.value ?? 0)
            guard value > 0 else { return nil }
            return PieSlice(name: account.name, value: value, colorIndex: idx)
        }
    }
}
