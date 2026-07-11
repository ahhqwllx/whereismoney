import SwiftUI

/// App 主题配色 —— 复用 HTML 仪表盘的深色配色方案
enum AppTheme {
    // MARK: - 背景层
    static let background = Color(hex: 0x000000)
    static let card        = Color(hex: 0x1C1C1E)
    static let cardSecondary = Color(hex: 0x2C2C2E)
    static let border      = Color(hex: 0x38383A)

    // MARK: - 文字
    static let text     = Color(hex: 0xE6EDF3)
    static let textDim  = Color(hex: 0x8B98A5)

    // MARK: - 语义色
    static let asset      = Color(hex: 0x34D399) // 资产绿
    static let liability  = Color(hex: 0xF87171) // 负债红
    static let summary    = Color(hex: 0x60A5FA) // 汇总蓝
    static let netAsset   = Color(hex: 0x4ADE80) // 净资产强调绿
    static let warning    = Color(hex: 0xF59E0B) // 警告橙
    static let danger     = Color(hex: 0xEF4444) // 危险红
    static let positive   = Color(hex: 0x22C55E) // 正向绿
    static let negative   = Color(hex: 0xF87171) // 负向红

    // MARK: - 图表配色
    static let assetColors: [Color] = [
        Color(hex: 0x60A5FA), Color(hex: 0xA78BFA), Color(hex: 0x34D399),
        Color(hex: 0xFBBF24), Color(hex: 0xF472B6), Color(hex: 0x22D3EE),
        Color(hex: 0xFB923C), Color(hex: 0x818CF8), Color(hex: 0x94A3B8),
    ]

    static let liabilityColors: [Color] = [
        Color(hex: 0xF87171), Color(hex: 0xEF4444), Color(hex: 0xFB923C),
        Color(hex: 0xF59E0B), Color(hex: 0xA78BFA),
    ]

    // MARK: - 卡片左边框颜色
    static func accentColor(for type: AccountType) -> Color {
        switch type {
        case .asset:     return asset
        case .liability: return liability
        }
    }
}

// MARK: - Color 扩展：支持 hex 初始化 + 深浅色自适应

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// 在浅色模式下自动提亮深色背景，使 App 在两种模式下都可用
    static func adaptive(dark: Color, light: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - View 扩展：卡片样式

extension View {
    /// 标准卡片样式：圆角 + 边框 + 背景
    func cardStyle(
        background: Color = AppTheme.card,
        border: Color = AppTheme.border
    ) -> some View {
        self
            .padding(16)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
