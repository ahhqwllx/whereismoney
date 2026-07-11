import SwiftUI
import SwiftData

/// 记录详情页 —— 查看某期记录的全部科目数值
struct RecordDetailView: View {
    @Environment(\.modelContext) private var context
    let record: Record

    @Query(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.order)])) private var accounts: [Account]
    @State private var showingEdit = false

    private var assetAccounts: [Account] {
        accounts.filter { $0.type == .asset }
    }

    private var liabilityAccounts: [Account] {
        accounts.filter { $0.type == .liability }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 顶部汇总卡
                summaryCard

                // 资产明细
                detailSection(title: "资产", accounts: assetAccounts, type: .asset)

                // 负债明细
                detailSection(title: "负债", accounts: liabilityAccounts, type: .liability)
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .navigationTitle(MoneyFormatter.date(record.date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Label("编辑", systemImage: "pencil")
                        .foregroundStyle(AppTheme.netAsset)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            RecordEditView(editingRecord: record)
        }
    }

    // MARK: - 汇总卡

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Text("净资产")
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)

            Text(MoneyFormatter.money(record.netAssets))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(record.netAssets >= 0 ? AppTheme.netAsset : AppTheme.negative)

            HStack(spacing: 12) {
                summaryItem(label: "总资产", value: record.totalAssets, color: AppTheme.asset)
                summaryItem(label: "总负债", value: record.totalLiabilities, color: AppTheme.liability)
                summaryItem(label: "负债率", value: record.debtToAssetRatio, color: AppTheme.warning, isPercent: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func summaryItem(label: String, value: Double, color: Color, isPercent: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textDim)
            Text(isPercent ? MoneyFormatter.percent(value) : MoneyFormatter.money(value))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 明细区

    private func detailSection(title: String, accounts: [Account], type: AccountType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.accentColor(for: type))
                    .frame(width: 3, height: 14)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text(MoneyFormatter.money(
                    type == .asset ? record.totalAssets : record.totalLiabilities
                ))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.accentColor(for: type))
            }

            VStack(spacing: 0) {
                ForEach(accounts) { account in
                    if let entry = record.entries.first(where: { $0.account?.id == account.id }) {
                        detailRow(name: account.name, value: entry.value, type: type)
                        if account.id != accounts.last?.id {
                            Divider()
                                .background(AppTheme.border)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
    }

    private func detailRow(name: String, value: Double, type: AccountType) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.text)
            Spacer()
            Text(MoneyFormatter.money(value))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(type == .liability ? AppTheme.liability : AppTheme.asset)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
