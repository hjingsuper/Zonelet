import AppKit
import Foundation

let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "dmg-background.png")
let canvas = NSSize(width: 720, height: 460)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvas.width),
    pixelsHigh: Int(canvas.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Unable to create bitmap\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
defer { NSGraphicsContext.restoreGraphicsState() }

NSColor(calibratedRed: 0.97, green: 0.98, blue: 1.0, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvas)).fill()

func roundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

roundedRect(
    NSRect(x: 54, y: 174, width: 238, height: 172),
    radius: 86,
    color: NSColor(calibratedRed: 0.91, green: 0.95, blue: 1.0, alpha: 1)
)
roundedRect(
    NSRect(x: 428, y: 174, width: 238, height: 172),
    radius: 86,
    color: NSColor(calibratedRed: 0.91, green: 0.95, blue: 1.0, alpha: 1)
)

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 320, y: 260))
arrow.line(to: NSPoint(x: 400, y: 260))
arrow.move(to: NSPoint(x: 373, y: 287))
arrow.line(to: NSPoint(x: 400, y: 260))
arrow.line(to: NSPoint(x: 373, y: 233))
arrow.lineWidth = 11
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
NSColor(calibratedRed: 0.20, green: 0.24, blue: 0.32, alpha: 0.86).setStroke()
arrow.stroke()

let titleStyle = NSMutableParagraphStyle()
titleStyle.alignment = .center
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 26, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.09, green: 0.12, blue: 0.18, alpha: 1),
    .paragraphStyle: titleStyle
]
let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
    .foregroundColor: NSColor(calibratedRed: 0.38, green: 0.43, blue: 0.52, alpha: 1),
    .paragraphStyle: titleStyle
]
let brandAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
    .foregroundColor: NSColor(calibratedRed: 0.19, green: 0.36, blue: 0.96, alpha: 1),
    .paragraphStyle: titleStyle
]

("ZONELET" as NSString).draw(
    in: NSRect(x: 0, y: 402, width: canvas.width, height: 24),
    withAttributes: brandAttributes
)
("拖动 Zonelet 到“应用程序”完成安装" as NSString).draw(
    in: NSRect(x: 0, y: 86, width: canvas.width, height: 38),
    withAttributes: titleAttributes
)
("Drag Zonelet to Applications" as NSString).draw(
    in: NSRect(x: 0, y: 56, width: canvas.width, height: 24),
    withAttributes: subtitleAttributes
)

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to render DMG background\n", stderr)
    exit(1)
}

try pngData.write(to: outputURL, options: .atomic)
