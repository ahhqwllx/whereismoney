import SwiftUI
import WebKit

/// ECharts WebView —— 用 WKWebView 加载 ECharts，实现与 HTML 仪表盘一致的交互效果
/// 支持 tooltip 悬停、十字线、dataZoom 缩放
struct EChartsWebView: UIViewRepresentable {
    let chartType: ChartType
    let data: EChartsData
    var fullscreen: Bool = false

    enum ChartType: String {
        case netAsset    // 净资产趋势 & 环比
        case assetStack  // 资产构成堆叠
        case liabStack   // 负债构成堆叠
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false

        let html = EChartsHTML.template
        webView.loadHTMLString(html, baseURL: nil)
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 等 ECharts 加载完成后注入数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadChart(webView: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var webView: WKWebView?
    }

    private func loadChart(webView: WKWebView) {
        let jsonData = data.toJSON()
        let fs = fullscreen ? "true" : "false"
        let js = "renderChart('\(chartType.rawValue)', \(jsonData), \(fs));"
        webView.evaluateJavaScript(js) { _, error in
            if let error {
                print("ECharts 渲染错误: \(error)")
            }
        }
    }
}

// MARK: - 图表数据模型

struct EChartsData {
    let dates: [String]
    let netAssets: [Double]
    let changes: [Double?]         // 环比，首期为 nil
    let assetSeries: [(name: String, values: [Double])]  // 资产各科目
    let liabilitySeries: [(name: String, values: [Double])] // 负债各科目（绝对值）

    func toJSON() -> String {
        var dict: [String: Any] = [:]
        dict["dates"] = dates
        dict["net"] = netAssets
        dict["changes"] = changes.map { c -> Any in c ?? NSNull() }

        dict["assetNames"] = assetSeries.map { $0.name }
        dict["assetValues"] = assetSeries.map { $0.values }

        dict["liabNames"] = liabilitySeries.map { $0.name }
        dict["liabValues"] = liabilitySeries.map { $0.values }

        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }
}

// MARK: - 从 ViewModel 构建数据

extension EChartsData {
    static func from(viewModel: FinanceViewModel) -> EChartsData {
        let dates = viewModel.netAssetPoints.map { MoneyFormatter.date($0.date) }
        let netAssets = viewModel.netAssetPoints.map { $0.netAssets }
        let changes = viewModel.netAssetPoints.map { $0.change }

        let assetNames = viewModel.assetStackPoints.first?.values.map { $0.name } ?? []
        let assetSeries: [(name: String, values: [Double])] = assetNames.enumerated().map { idx, name in
            let values = viewModel.assetStackPoints.map { $0.values[idx].value }
            return (name, values)
        }

        let liabNames = viewModel.liabilityStackPoints.first?.values.map { $0.name } ?? []
        let liabilitySeries: [(name: String, values: [Double])] = liabNames.enumerated().map { idx, name in
            let values = viewModel.liabilityStackPoints.map { $0.values[idx].value }
            return (name, values)
        }

        return EChartsData(
            dates: dates,
            netAssets: netAssets,
            changes: changes,
            assetSeries: assetSeries,
            liabilitySeries: liabilitySeries
        )
    }
}
