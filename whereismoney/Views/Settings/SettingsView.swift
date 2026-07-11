import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 设置页 —— iCloud 同步、提醒、导入导出
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(Record.chronological) private var records: [Record]
    @Query(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.order)])) private var accounts: [Account]

    @AppStorage(AppConstants.UserDefaultsKey.reminderEnabled) private var reminderEnabled = false
    @AppStorage(AppConstants.UserDefaultsKey.reminderWeekday) private var reminderWeekday = 1
    @AppStorage(AppConstants.UserDefaultsKey.reminderHour) private var reminderHour = 20
    @AppStorage(AppConstants.UserDefaultsKey.reminderMinute) private var reminderMinute = 0
    @AppStorage(AppConstants.UserDefaultsKey.anomalyThreshold) private var anomalyThreshold = AppConstants.defaultAnomalyThreshold

    @State private var showingFilePicker = false
    @State private var showingExportSuccess = false
    @State private var showingImportResult = false
    @State private var importResult: CSVImporter.ImportResult?
    @State private var exportURL: URL?
    @State private var showingClearConfirm = false
    @State private var showingImportModeSheet = false
    @State private var pendingCSVText: String?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 数据管理
                Section("数据管理") {
                    NavigationLink {
                        AccountsManageView()
                    } label: {
                        Label("科目管理", systemImage: "list.bullet.indent")
                    }

                    Button {
                        exportCSV()
                    } label: {
                        Label("导出 CSV", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("导入 CSV", systemImage: "square.and.arrow.down")
                    }

                    Button(role: .destructive) {
                        showingClearConfirm = true
                    } label: {
                        Label("清空所有记录", systemImage: "trash")
                    }
                    .disabled(records.isEmpty)
                }

                // MARK: - 提醒
                Section("定期录入提醒") {
                    Toggle("启用提醒", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestAuthorization()
                                NotificationManager.shared.scheduleReminder(
                                    weekday: reminderWeekday,
                                    hour: reminderHour,
                                    minute: reminderMinute
                                )
                            } else {
                                NotificationManager.shared.cancelReminder()
                            }
                        }

                    if reminderEnabled {
                        Picker("提醒日", selection: $reminderWeekday) {
                            Text("周日").tag(1)
                            Text("周一").tag(2)
                            Text("周二").tag(3)
                            Text("周三").tag(4)
                            Text("周四").tag(5)
                            Text("周五").tag(6)
                            Text("周六").tag(7)
                        }
                        .onChange(of: reminderWeekday) { _, _ in scheduleReminder() }

                        DatePicker("提醒时间", selection: timeBinding, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderHour) { _, _ in scheduleReminder() }
                            .onChange(of: reminderMinute) { _, _ in scheduleReminder() }
                    }
                }

                // MARK: - 大额变动
                Section("大额变动推送") {
                    HStack {
                        Text("净资产环比阈值")
                        Spacer()
                        TextField("", value: $anomalyThreshold, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("元")
                            .foregroundStyle(AppTheme.textDim)
                    }
                    Text("当净资产环比变化超过此值时推送通知")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textDim)
                }

                // MARK: - 关于
                Section("关于") {
                    HStack {
                        Label("版本", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(AppTheme.textDim)
                    }

                    Link(destination: URL(string: "https://developer.apple.com/icloud/cloudkit/")!) {
                        Label("CloudKit 文档", systemImage: "icloud")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImportResult) {
                if let result = importResult {
                    ImportResultSheet(result: result)
                }
            }
            .sheet(isPresented: $showingExportSuccess) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .confirmationDialog(
                "导入 CSV",
                isPresented: $showingImportModeSheet,
                titleVisibility: .visible
            ) {
                Button("清空后全量导入") {
                    performImport(clearFirst: true)
                }
                Button("追加导入") {
                    performImport(clearFirst: false)
                }
                Button("取消", role: .cancel) {}
            } message: {
                if records.isEmpty {
                    Text("将导入 \(pendingCSVText.map { countCSVLines($0) } ?? 0) 条记录")
                } else {
                    Text("当前有 \(records.count) 条记录。「清空后导入」会删除现有记录再导入；「追加导入」会保留现有记录。")
                }
            }
            .confirmationDialog(
                "清空所有记录？",
                isPresented: $showingClearConfirm,
                titleVisibility: .visible
            ) {
                Button("清空", role: .destructive) {
                    clearAllRecords()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("这将删除所有 \(records.count) 条财务记录，此操作不可撤销。")
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .text],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    // MARK: - 时间绑定

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = comps.hour ?? 20
                reminderMinute = comps.minute ?? 0
            }
        )
    }

    private func scheduleReminder() {
        NotificationManager.shared.scheduleReminder(
            weekday: reminderWeekday,
            hour: reminderHour,
            minute: reminderMinute
        )
    }

    // MARK: - 导入导出

    private func exportCSV() {
        let url = CSVExporter.exportToFile(records: records, accounts: accounts)
        exportURL = url
        showingExportSuccess = true
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }

                let csvText = try String(contentsOf: url, encoding: .utf8)
                pendingCSVText = csvText
                showingImportModeSheet = true
            } catch {
                importResult = CSVImporter.ImportResult(recordsImported: 0, errors: ["读取文件失败: \(error.localizedDescription)"])
                showingImportResult = true
            }
        case .failure(let error):
            importResult = CSVImporter.ImportResult(recordsImported: 0, errors: ["导入失败: \(error.localizedDescription)"])
            showingImportResult = true
        }
    }

    private func performImport(clearFirst: Bool) {
        guard let csvText = pendingCSVText else { return }

        if clearFirst {
            clearAllRecords()
        }

        let importRes = CSVImporter.`import`(csvText: csvText, into: context, existingAccounts: accounts)
        try? context.save()
        importResult = importRes
        showingImportResult = true
        pendingCSVText = nil

        NotificationCenter.default.post(name: AppConstants.dataChangedNotification, object: nil)
    }

    private func clearAllRecords() {
        for record in records {
            context.delete(record)
        }
        try? context.save()
        NotificationCenter.default.post(name: AppConstants.dataChangedNotification, object: nil)
    }

    private func countCSVLines(_ text: String) -> Int {
        let cleaned = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        return cleaned.components(separatedBy: .newlines).filter { !$0.isEmpty }.count - 1
    }
}

// MARK: - 导入结果 Sheet

private struct ImportResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    let result: CSVImporter.ImportResult

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: result.errors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(result.errors.isEmpty ? AppTheme.positive : AppTheme.warning)

                Text("成功导入 \(result.recordsImported) 条记录")
                    .font(.headline)

                if !result.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("错误信息")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textDim)
                        ForEach(result.errors, id: \.self) { error in
                            Text("• \(error)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.negative)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()

                Button("完成") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.netAsset)
            }
            .padding(24)
            .navigationTitle("导入结果")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - 分享 Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
