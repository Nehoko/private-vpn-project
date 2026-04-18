import AppKit
import Foundation

let outputSizes = [16, 32, 64, 128, 256, 512]

guard CommandLine.arguments.count == 2 else {
    fputs("usage: render_app_icon.swift <iconset_dir>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let basePath = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.08, green: 0.24, blue: 0.53, alpha: 1),
        NSColor(calibratedRed: 0.09, green: 0.56, blue: 0.91, alpha: 1),
    ])?.draw(in: basePath, angle: -90)

    let halo = NSBezierPath(ovalIn: rect.insetBy(dx: size * 0.14, dy: size * 0.14))
    NSColor.white.withAlphaComponent(0.08).setFill()
    halo.fill()

    let shield = NSBezierPath()
    shield.move(to: CGPoint(x: size * 0.50, y: size * 0.80))
    shield.curve(to: CGPoint(x: size * 0.75, y: size * 0.63),
                 controlPoint1: CGPoint(x: size * 0.64, y: size * 0.79),
                 controlPoint2: CGPoint(x: size * 0.74, y: size * 0.73))
    shield.line(to: CGPoint(x: size * 0.72, y: size * 0.38))
    shield.curve(to: CGPoint(x: size * 0.50, y: size * 0.18),
                 controlPoint1: CGPoint(x: size * 0.71, y: size * 0.28),
                 controlPoint2: CGPoint(x: size * 0.59, y: size * 0.21))
    shield.curve(to: CGPoint(x: size * 0.28, y: size * 0.38),
                 controlPoint1: CGPoint(x: size * 0.41, y: size * 0.21),
                 controlPoint2: CGPoint(x: size * 0.29, y: size * 0.28))
    shield.line(to: CGPoint(x: size * 0.25, y: size * 0.63))
    shield.curve(to: CGPoint(x: size * 0.50, y: size * 0.80),
                 controlPoint1: CGPoint(x: size * 0.26, y: size * 0.73),
                 controlPoint2: CGPoint(x: size * 0.36, y: size * 0.79))
    shield.close()

    NSColor.white.withAlphaComponent(0.95).setFill()
    shield.fill()

    let tunnel = NSBezierPath()
    tunnel.move(to: CGPoint(x: size * 0.33, y: size * 0.48))
    tunnel.curve(to: CGPoint(x: size * 0.68, y: size * 0.55),
                 controlPoint1: CGPoint(x: size * 0.42, y: size * 0.62),
                 controlPoint2: CGPoint(x: size * 0.57, y: size * 0.62))
    tunnel.curve(to: CGPoint(x: size * 0.66, y: size * 0.42),
                 controlPoint1: CGPoint(x: size * 0.74, y: size * 0.51),
                 controlPoint2: CGPoint(x: size * 0.73, y: size * 0.45))
    tunnel.curve(to: CGPoint(x: size * 0.35, y: size * 0.36),
                 controlPoint1: CGPoint(x: size * 0.58, y: size * 0.36),
                 controlPoint2: CGPoint(x: size * 0.44, y: size * 0.34))
    tunnel.close()

    NSColor(calibratedRed: 0.10, green: 0.43, blue: 0.80, alpha: 1).setFill()
    tunnel.fill()

    let dot = NSBezierPath(ovalIn: NSRect(x: size * 0.44, y: size * 0.41, width: size * 0.12, height: size * 0.12))
    NSColor.white.setFill()
    dot.fill()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "render_app_icon", code: 1)
    }
    try png.write(to: url)
}

for size in outputSizes {
    let image = drawIcon(size: CGFloat(size))
    try writePNG(image, to: outputURL.appendingPathComponent("icon_\(size)x\(size).png"))

    let doubleSize = size * 2
    let retinaImage = drawIcon(size: CGFloat(doubleSize))
    try writePNG(retinaImage, to: outputURL.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
