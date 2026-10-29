import AppKit

let iconset = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let size = CGFloat(pixels)
    let tile = NSRect(x: 0, y: 0, width: size, height: size).insetBy(dx: size * 0.1, dy: size * 0.1)
    let shape = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    NSGradient(starting: NSColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1), ending: NSColor(red: 0.18, green: 0.52, blue: 0.93, alpha: 1))!
        .draw(in: shape, angle: -90)

    let barHeight = tile.height * 0.28
    let bar = NSRect(x: tile.minX + tile.width * 0.12, y: tile.midY - barHeight / 2, width: tile.width * 0.76, height: barHeight)
    NSColor(white: 1, alpha: 0.3).setFill()
    NSBezierPath(roundedRect: bar, xRadius: barHeight / 2, yRadius: barHeight / 2).fill()

    let config = NSImage.SymbolConfiguration(pointSize: tile.width * 0.22, weight: .regular).applying(.preferringMulticolor())
    let symbol = NSImage(systemSymbolName: "cloud.sun.fill", accessibilityDescription: nil)!.withSymbolConfiguration(config)!
    let symbolRect = NSRect(x: tile.midX - symbol.size.width / 2, y: tile.midY - symbol.size.height / 2, width: symbol.size.width, height: symbol.size.height)
    symbol.draw(in: symbolRect)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    try render(pixels: points).write(to: URL(fileURLWithPath: "\(iconset)/icon_\(points)x\(points).png"))
    try render(pixels: points * 2).write(to: URL(fileURLWithPath: "\(iconset)/icon_\(points)x\(points)@2x.png"))
}
