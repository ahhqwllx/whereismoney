import SwiftUI
import SwiftData

/// 科目管理页 —— 增删改 + 排序 + 阈值设置
struct AccountsManageView: View {
    @Environment(\.modelContext) private var context
    @Query(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.order)])) private var accounts: [Account]

    @State private var showingAdd = false
    @State private var editingAccount: Account?

    private var assetAccounts: [Account] {
        accounts.filter { $0.type == .asset }
    }

    private var liabilityAccounts: [Account] {
        accounts.filter { $0.type == .liability }
    }

    var body: some View {
        List {
            Section("资产") {
                ForEach(assetAccounts) { account in
                    AccountRow(account: account)
                        .contentShape(Rectangle())
                        .onTapGesture { editingAccount = account }
                        .listRowBackground(AppTheme.card)
                }
                .onMove { offsets, dest in
                    moveAccounts(assetAccounts, offsets: offsets, dest: dest, baseOrder: 0)
                }
                .onDelete { offsets in
                    deleteAccounts(assetAccounts, at: offsets)
                }
            }

            Section("负债") {
                ForEach(liabilityAccounts) { account in
                    AccountRow(account: account)
                        .contentShape(Rectangle())
                        .onTapGesture { editingAccount = account }
                        .listRowBackground(AppTheme.card)
                }
                .onMove { offsets, dest in
                    let baseOrder = assetAccounts.count
                    moveAccounts(liabilityAccounts, offsets: offsets, dest: dest, baseOrder: baseOrder)
                }
                .onDelete { offsets in
                    deleteAccounts(liabilityAccounts, at: offsets)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("资产类别管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            #endif
        }
        .sheet(isPresented: $showingAdd) {
            AccountEditSheet()
        }
        .sheet(item: $editingAccount) { account in
            AccountEditSheet(editingAccount: account)
        }
    }

    // MARK: - 操作

    private func moveAccounts(_ sectionAccounts: [Account], offsets: IndexSet, dest: Int, baseOrder: Int) {
        let sorted = sectionAccounts.sorted { $0.order < $1.order }
        var reordered = sorted
        reordered.move(fromOffsets: offsets, toOffset: dest)

        for (i, account) in reordered.enumerated() {
            if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
                accounts[idx].order = baseOrder + i
            }
        }
        try? context.save()
    }

    private func deleteAccounts(_ sectionAccounts: [Account], at offsets: IndexSet) {
        for index in offsets {
            let account = sectionAccounts[index]
            // 仅移除关联，不级联删除历史 entry
            context.delete(account)
        }
        try? context.save()
    }
}

// MARK: - 科目行

private struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppTheme.accentColor(for: account.type))
                .frame(width: 8, height: 8)

            Text(account.name)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.text)

            Spacer()

            if let threshold = account.threshold {
                Text("阈值 \(MoneyFormatter.money(threshold))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textDim)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 科目编辑 Sheet

struct AccountEditSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editingAccount: Account?

    @State private var name = ""
    @State private var type: AccountType = .asset
    @State private var thresholdEnabled = false
    @State private var thresholdString = ""

    private var isNew: Bool { editingAccount == nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("科目名称", text: $name)

                    Picker("类型", selection: $type) {
                        ForEach(AccountType.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                }

                Section("大额变动提醒") {
                    Toggle("启用阈值检测", isOn: $thresholdEnabled)
                    if thresholdEnabled {
                        TextField("阈值金额", text: $thresholdString)
                            .keyboardType(.decimalPad)
                    }
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            deleteAccount()
                        } label: {
                            Text("删除此科目")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(isNew ? "新增科目" : "编辑科目")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { loadData() }
    }

    private func loadData() {
        if let account = editingAccount {
            name = account.name
            type = account.type
            if let threshold = account.threshold {
                thresholdEnabled = true
                thresholdString = String(format: "%.0f", threshold)
            }
        }
    }

    private func save() {
        let threshold = thresholdEnabled ? (Double(thresholdString) ?? 0) : nil

        if let account = editingAccount {
            account.name = name
            account.type = type
            account.threshold = threshold
        } else {
            // 新增科目，order 设为当前同类型科目数量（排到末尾）
            let existingCount = (try? context.fetch(FetchDescriptor<Account>()))?
                .filter { $0.type == type }.count ?? 0
            let account = Account(name: name, type: type, order: existingCount, threshold: threshold)
            context.insert(account)
        }
        try? context.save()
        dismiss()
    }

    private func deleteAccount() {
        if let account = editingAccount {
            context.delete(account)
            try? context.save()
        }
        dismiss()
    }
}
