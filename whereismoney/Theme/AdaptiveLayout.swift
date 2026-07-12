import SwiftUI

/// 自适应布局 —— 在 iPad 上自动放大 padding 和字体，不影响 iPhone
struct AdaptiveLayout {
    /// 根据水平尺寸类别返回内容水平边距
    /// iPhone（compact）: 16pt，iPad（regular）: 24pt
    static func horizontalPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 24 : 16
    }

    /// 卡片内边距
    static func cardPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 24 : 16
    }

    /// KPI 数值字号
    static func kpiValueSize(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 30 : 22
    }

    /// KPI 标签字号
    static func kpiLabelSize(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 14 : 12
    }

    /// KPI 副文字字号
    static func kpiSubSize(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 12 : 10
    }

    /// 图表高度
    static func chartHeight(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 340 : 260
    }

    /// 标题字号
    static func titleSize(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 20 : 17
    }

    /// 正文字号
    static func bodySize(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 17 : 15
    }
}

/// View 扩展：方便获取当前 sizeClass
extension View {
    /// 在 iPad 上限制内容最大宽度并居中，避免内容过宽
    func padMaxWidth(_ sizeClass: UserInterfaceSizeClass?) -> some View {
        self.frame(maxWidth: sizeClass == .regular ? 900 : .infinity, alignment: .center)
    }
}
