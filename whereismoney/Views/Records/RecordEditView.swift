import SwiftUI
import SwiftData

/// 记录录入/编辑页 —— 分组表单 + 数字键盘 + 实时净资产计算
struct RecordEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// 编辑现有记录时传入
    var editingRecord: Record?

    @Query(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.order)])) private var accounts: [Account]

    @State private var date: Date = .now
    /// 科目ID -> 输入的字符串值
    @State private var inputValues: [UUID: String] = [:]
    /// 科目ID -> 最新一期参考值（新增模式下用于灰色提示）
    @State private var previousValues: [UUID: Double] = [:]
    @FocusState private var focusedAccountId: UUID?

    private var isNew: Bool { editingRecord == nil }

    private var assetAccounts: [Account] {
        accounts.filter { $0.type == .asset }
    }

    private var liabilityAccounts: [Account] {
        accounts.filter { $0.type == .liability }
    }

    /// 实时计算的净资产（用于顶部显示）
    private var liveNetAssets: Double {
        let assets = assetAccounts.reduce(0.0) { sum, acc in
            sum + (Double(inputValues[acc.id] ?? "") ?? 0)
        }
        let liabilities = liabilityAccounts.reduce(0.0) { sum, acc in
            // 负债输入为正数，存储为负值
            sum - (Double(inputValues[acc.id] ?? "") ?? 0)
        }
        return assets + liabilities
    }

    private var liveTotalAssets: Double {
        assetAccounts.reduce(0.0) { sum, acc in
            sum + (Double(inputValues[acc.id] ?? "") ?? 0)
        }
    }

    private var liveTotalLiabilities: Double {
        liabilityAccounts.reduce(0.0) { sum, acc in
            sum - (Double(inputValues[acc.id] ?? "") ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // 实时净资产卡片
                        liveNetCard

                        // 日期选择
                        DatePicker("记录日期", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 16)

                        // 资产分组
                        accountSection(title: "资产", accounts: assetAccounts, type: .asset)

                        // 负债分组
                        accountSection(title: "负债", accounts: liabilityAccounts, type: .liability)
                    }
                    .padding(.bottom, 80)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(AppTheme.background)
                .navigationTitle(isNew ? "新增记录" : "编辑记录")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") { dismiss() }
                            .foregroundStyle(AppTheme.textDim)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("保存") { save() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.netAsset)
                    }
                    ToolbarItem(placement: .keyboard) {
                        Button("完成") {
                            focusedAccountId = nil
                        }
                    }
                }
                .onChange(of: focusedAccountId) { _, newId in
                    // 键盘弹出时，把当前聚焦的输入框滚动到可视区域中央
                    if let id = newId {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .onAppear { loadData() }
    }

    // MARK: - 实时净资产卡片

    private var liveNetCard: some View {
        VStack(spacing: 8) {
            Text("实时净资产")
                .font(.caption)
                .foregroundStyle(AppTheme.textDim)

            Text(MoneyFormatter.money(liveNetAssets))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(liveNetAssets >= 0 ? AppTheme.netAsset : AppTheme.negative)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("总资产")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textDim)
                    Text(MoneyFormatter.compact(liveTotalAssets))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.asset)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("总负债")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textDim)
                    Text(MoneyFormatter.compact(liveTotalLiabilities))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.liability)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                if liveTotalAssets > 0 {
                    VStack(spacing: 2) {
                        Text("负债率")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.textDim)
                        Text(MoneyFormatter.percent(abs(liveTotalLiabilities) / liveTotalAssets * 100))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.warning)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - 科目输入分组

    private func accountSection(title: String, accounts: [Account], type: AccountType) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 分组标题
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.accentColor(for: type))
                    .frame(width: 3, height: 14)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("\(accounts.count) 项")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textDim)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // 科目输入行
            VStack(spacing: 0) {
                ForEach(accounts) { account in
                    accountInputRow(account: account, type: type)
                    if account.id != accounts.last?.id {
                        Divider()
                            .background(AppTheme.border)
                            .padding(.leading, 48)
                    }
                }
            }
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }

    private func accountInputRow(account: Account, type: AccountType) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(AppTheme.accentColor(for: type))
                .frame(width: 6, height: 6)

            // 科目名 + 上期参考值
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)

                // 新增模式下，显示最新一期的参考值
                if isNew, let prev = previousValues[account.id], prev != 0 {
                    Text("上期 \(MoneyFormatter.money(prev))")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textDim)
                }
            }

            Spacer(minLength: 8)

            // 金额输入框
            HStack(spacing: 2) {
                if type == .liability {
                    Text("-¥")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textDim)
                }
                TextField("0", text: bindingFor(account))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(type == .liability ? AppTheme.liability : AppTheme.asset)
                    .frame(minWidth: 60)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(AppTheme.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .focused($focusedAccountId, equals: account.id)
        }
        .id(account.id)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedAccountId = account.id
        }
    }

    // MARK: - 数据加载与保存

    private func bindingFor(_ account: Account) -> Binding<String> {
        Binding(
            get: {
                // 负债类型：去掉存储值中的负号，只显示数字（前缀 -¥ 已表示负数）
                let raw = inputValues[account.id] ?? ""
                if account.type == .liability && raw.hasPrefix("-") {
                    return String(raw.dropFirst())
                }
                return raw
            },
            set: { newValue in
                if account.type == .liability {
                    // 负债类型：去掉用户可能输入的负号，统一存储为纯数字（前缀 -¥ 已表示负数）
                    let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                    inputValues[account.id] = trimmed.hasPrefix("-") ? String(trimmed.dropFirst()) : trimmed
                } else {
                    inputValues[account.id] = newValue
                }
            }
        )
    }

    private func loadData() {
        if let record = editingRecord {
            // 编辑模式：加载当前记录的数据
            date = record.date
            for entry in record.entries {
                if let accountId = entry.account?.id {
                    // 负债存储为负值，输入框显示绝对值
                    inputValues[accountId] = String(format: "%.2f", abs(entry.value))
                }
            }
        } else {
            // 新增模式：查找日期早于当前 date 的最新一期记录，用于显示参考值
            loadPreviousValues()
        }
    }

    /// 加载最新一期的科目数值作为参考
    private func loadPreviousValues() {
        let allRecords = (try? context.fetch(Record.reverseChronological)) ?? []
        // 找到日期早于当前 date 的第一条记录
        let prev = allRecords.first { $0.date < date }
        guard let prev else { return }
        for entry in prev.entries {
            if let accountId = entry.account?.id {
                previousValues[accountId] = entry.value
            }
        }
    }

    private func save() {
        if let record = editingRecord {
            // 更新现有记录
            updateRecord(record)
        } else {
            // 创建新记录
            let record = Record(date: date)
            for account in accounts {
                let inputStr = inputValues[account.id] ?? ""
                let value = Double(inputStr) ?? 0
                // 负债存储为负值
                let storedValue = account.type == .liability ? -abs(value) : value
                let entry = Entry(value: storedValue, account: account, record: record)
                record.entries.append(entry)
            }
            context.insert(record)

            // 检查大额变动
            checkAnomaly(for: record)
        }

        try? context.save()

        // 通知仪表盘刷新
        NotificationCenter.default.post(name: AppConstants.dataChangedNotification, object: nil)

        dismiss()
    }

    private func updateRecord(_ record: Record) {
        record.date = date

        // 更新已有 entry 或创建新 entry
        for account in accounts {
            let inputStr = inputValues[account.id] ?? ""
            let value = Double(inputStr) ?? 0
            let storedValue = account.type == .liability ? -abs(value) : value

            if let existingEntry = record.entries.first(where: { $0.account?.id == account.id }) {
                existingEntry.value = storedValue
            } else {
                let entry = Entry(value: storedValue, account: account, record: record)
                record.entries.append(entry)
            }
        }

        // 检查大额变动
        checkAnomaly(for: record)
    }

    /// 检查净资产环比是否触发大额变动通知
    private func checkAnomaly(for record: Record) {
        let allRecords = (try? context.fetch(Record.chronological)) ?? []
        let sorted = allRecords.sorted { $0.date < $1.date }

        guard let currentIdx = sorted.firstIndex(where: { $0.id == record.id }),
              currentIdx > 0 else { return }

        let prev = sorted[currentIdx - 1]
        let change = record.netAssets - prev.netAssets

        let threshold = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKey.anomalyThreshold) as? Double
            ?? AppConstants.defaultAnomalyThreshold

        NotificationManager.shared.checkAnomaly(netAssetChange: change, threshold: threshold)
    }
}
