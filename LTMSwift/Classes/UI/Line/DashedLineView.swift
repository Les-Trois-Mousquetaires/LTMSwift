//
//  DashedLineView.swift
//  LTMSwift
//
//  Created by coenen on 2026/10/22.
//

import UIKit

public final class DashedLineView: UIView {
    public enum Direction {
        /** 水平居中。 */
        case horizontal
        /** 垂直居中。 */
        case vertical
        /** 左上至右下。 */
        case diagonalDown
        /** 左下至右上。 */
        case diagonalUp
        /** 自定义归一化端点，坐标范围为 0...1，基于内边距后的区域。 */
        case custom(start: CGPoint, end: CGPoint)
    }

    // 通用线条绘制配置；尺寸及间隔单位均为点。
    public struct Config {
        // 绘制方向。
        public var direction: Direction = .horizontal
        // 线条颜色。
        public var color: UIColor = UIColor.black.withAlphaComponent(0.1)
        // 沿线条起点至终点等距渐变，至少两个颜色时优先于 color，与赋值先后无关。
        public var gradientColors: [UIColor] = []
        // 线宽，单位为点；必须为有限正数。
        public var lineWidth: CGFloat = 2
        // 实线段和空白段交替长度，单位为点；空数组表示实线，忽略非正数和非有限值。
        public var dashLengths: [CGFloat] = [2, 4]
        // 虚线起始偏移，单位为点。
        public var dashPhase: CGFloat = 0
        // 端点样式；square / round 每端延伸半个线宽，间隔过小会连成实线。
        public var lineCap: CGLineCap = .square
        // 绘制区域内边距；需为非负有限值，默认不额外缩进。
        public var contentInsets: UIEdgeInsets = .zero

        /** 创建默认线条配置，随后通过属性调整样式。 */
        public init() {}
    }

    // 可在创建后配置或更新，赋值后自动重绘。
    public var config = Config() {
        didSet { self.setNeedsDisplay() }
    }

    /**
     初始化通用线条视图，尺寸变化时重新绘制。

     - parameters frame 初始位置及尺寸
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.contentMode = .redraw
    }

    /**
     支持从归档创建。

     - parameters coder 解码器
     */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.contentMode = .redraw
    }

    /**
     根据配置绘制线条，使用 bounds 保证局部刷新不改变端点位置。

     - parameters rect 当前需要重绘的区域
     */
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        let config = self.config
        let insets = config.contentInsets
        guard config.lineWidth.isFinite, config.lineWidth > 0,
              [insets.top, insets.left, insets.bottom, insets.right].allSatisfy({ $0.isFinite && $0 >= 0 }),
              let context = UIGraphicsGetCurrentContext() else { return }
        let area = self.bounds.inset(by: insets)
        guard area.width > 0, area.height > 0 else { return }
        guard let (startPoint, endPoint) = self.endpoints(in: area) else { return }
        context.saveGState()
        defer { context.restoreGState() }
        context.setLineCap(config.lineCap)
        context.setStrokeColor(config.color.resolvedColor(with: self.traitCollection).cgColor)
        context.setLineWidth(config.lineWidth)
        let phase = config.dashPhase.isFinite ? config.dashPhase : 0
        let lengths = config.dashLengths.filter { $0.isFinite && $0 > 0 }
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        if config.gradientColors.count >= 2, startPoint != endPoint,
           let gradient = CGGradient(colorsSpace: nil,
                                     colors: config.gradientColors.map { $0.resolvedColor(with: self.traitCollection).cgColor } as CFArray,
                                     locations: nil) {
            // 先生成虚线及其描边轮廓，再裁剪渐变，避免填充虚线间的空隙。
            let dashedPath: CGPath = lengths.isEmpty ? path : path.copy(dashingWithPhase: phase, lengths: lengths)
            let outline = dashedPath.copy(strokingWithWidth: config.lineWidth, lineCap: config.lineCap,
                                          lineJoin: .miter, miterLimit: 10)
            context.addPath(outline)
            context.clip()
            context.drawLinearGradient(gradient, start: startPoint, end: endPoint,
                                       options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        } else {
            context.setLineDash(phase: phase, lengths: lengths)
            context.addPath(path)
            context.strokePath()
        }
    }
}

private extension DashedLineView {
    /**
     将方向或归一化坐标转换为实际绘制端点。

     - parameters area 去除内边距后的绘制区域
     */
    func endpoints(in area: CGRect) -> (CGPoint, CGPoint)? {
        let start: CGPoint
        let end: CGPoint
        switch self.config.direction {
        case .horizontal:
            start = CGPoint(x: 0, y: 0.5)
            end = CGPoint(x: 1, y: 0.5)
        case .vertical:
            start = CGPoint(x: 0.5, y: 0)
            end = CGPoint(x: 0.5, y: 1)
        case .diagonalDown:
            start = .zero
            end = CGPoint(x: 1, y: 1)
        case .diagonalUp:
            start = CGPoint(x: 0, y: 1)
            end = CGPoint(x: 1, y: 0)
        case .custom(let customStart, let customEnd):
            start = customStart
            end = customEnd
        }
        guard [start.x, start.y, end.x, end.y].allSatisfy({ $0.isFinite && (0...1).contains($0) }) else { return nil }
        return (
            CGPoint(x: area.minX + start.x * area.width, y: area.minY + start.y * area.height),
            CGPoint(x: area.minX + end.x * area.width, y: area.minY + end.y * area.height)
        )
    }
}
