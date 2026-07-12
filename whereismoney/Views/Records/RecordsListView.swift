import SwiftUI
import SwiftData

/// 记录列表页 —— 对应 HTML 数据表
struct RecordsListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Query(Record.reverseChronological) private var records: [Record]

    @State private var searchText = ""
    @State private var showingEdit = false
    @State private var editingRecord: Record?

    private var filteredRecords: [Record] {
        if searchText.isEmpty {
            return records
        }
        return records.filter { record in
            MoneyFormatter.date(record.date).contains(searchText)
        }
    }

    var body: some View {
        Group {
            if hSizeClass == .regular {
                recordsContent
            } else {
                NavigationStack {
                    recordsContent
                }
            }
        }
    }

    private var recordsContent: some View {
        Group {
            if records.isEmpty {
                EmptyRecordsView()
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        NavigationLink {
                            RecordDetailView(record: record)
                        } label: {
                            RecordRow(record: record, allRecords: records)
                        }
                        .listRowBackground(AppTheme.card)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteRecord(record)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }

                            Button {
                                editingRecord = record
                            } label: {
                                Label("编辑", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
            }
        }
        .navigationTitle("记录")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "搜索日期，如 2026-05")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.netAsset)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            RecordEditView()
        }
        .sheet(item: $editingRecord) { record in
            RecordEditView(editingRecord: record)
        }
    }

    private func deleteRecord(_ record: Record) {
        context.delete(record)
        try? context.save()
        NotificationCenter.default.post(name: AppConstants.dataChangedNotification, object: nil)
    }
}

// MARK: - 记录行

private struct RecordRow: View {
    let record: Record
    let allRecords: [Record]

    private var change: Double? {
        guard let idx = allRecords.firstIndex(where: { $0.id == record.id }),
              idx < allRecords.count - 1 else { return nil }
        // allRecords 是降序的，所以 idx+1 是时间更早的记录
        return record.netAssets - allRecords[idx + 1].netAssets
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日期 + 环比 + 编辑按钮
            HStack {
                Text(MoneyFormatter.dateWithWeekday(record.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.text)

                Spacer()

                if let change {
                    Text(MoneyFormatter.signedMoney(change))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(change >= 0 ? AppTheme.positive : AppTheme.negative)
                }
            }

            // 净资产
            HStack {
                Text("净资产")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textDim)
                Spacer()
                Text(MoneyFormatter.money(record.netAssets))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.netAsset)
            }

            // 总资产 / 总负债 / 负债率
            HStack(spacing: 8) {
                Label(MoneyFormatter.compact(record.totalAssets), systemImage: "plus.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundStyle(AppTheme.asset)
                    .lineLimit(1)

                Label(MoneyFormatter.compact(record.totalLiabilities), systemImage: "minus.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundStyle(AppTheme.liability)
                    .lineLimit(1)

                Spacer()

                Text(MoneyFormatter.percent(record.debtToAssetRatio))
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 空状态

private struct EmptyRecordsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.textDim)

            Text("还没有记录")
                .font(.headline)
                .foregroundStyle(AppTheme.text)

            Text("点击右上角 + 添加你的第一条财务记录")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textDim)
        }
    }
}
