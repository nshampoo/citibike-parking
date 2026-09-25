// Draws the DockNearby app icon: a line-art step-through bike docked at a station post.
// Writes the three iOS icon variants (default, dark, tinted) into the app's asset catalog.
//
//   swift Design/make-icon.swift            # from the repo root
//   swift Design/make-icon.swift <out-dir>  # somewhere else, e.g. to preview
//
// Tweak the palette or geometry below, re-run, rebuild.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024.0

// MARK: Palette

struct RGB {
    let r, g, b: Double
    init(_ hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }
    var cg: CGColor { CGColor(red: r, green: g, blue: b, alpha: 1) }
}

struct Palette {
    let backgroundTop: RGB?      // nil = transparent (the tinted variant)
    let backgroundBottom: RGB?
    let bike: RGB
    let ground: RGB
    let dock: RGB
    let light: RGB
}

let palettes: [String: Palette] = [
    // Graphite background, silver bike, a Citi Bike-ish (not exact) blue dock.
    "AppIcon": Palette(backgroundTop: RGB(0x2A2E35), backgroundBottom: RGB(0x0F1114),
                       bike: RGB(0xD5DAE1), ground: RGB(0x5B626C), dock: RGB(0x2F86E8), light: RGB(0x6FB4FF)),
    // Dark mode: same art on near-black.
    "AppIcon-Dark": Palette(backgroundTop: RGB(0x15171A), backgroundBottom: RGB(0x000000),
                            bike: RGB(0xC9CED6), ground: RGB(0x4A5058), dock: RGB(0x3A8FF0), light: RGB(0x7DBCFF)),
    // Tinted: grayscale on transparent; iOS recolors it with the user's tint.
    "AppIcon-Tinted": Palette(backgroundTop: nil, backgroundBottom: nil,
                              bike: RGB(0xFFFFFF), ground: RGB(0x8A8A8A), dock: RGB(0xBDBDBD), light: RGB(0xFFFFFF)),
]

// MARK: Drawing (top-left origin, 1024 × 1024)

func draw(_ p: Palette, in ctx: CGContext) {
    ctx.translateBy(x: 0, y: size)
    ctx.scaleBy(x: 1, y: -1)

    if let top = p.backgroundTop, let bottom = p.backgroundBottom {
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                  colors: [top.cg, bottom.cg] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size), options: [])
    }

    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    func stroke(_ color: RGB, width: Double, _ build: (CGMutablePath) -> Void) {
        let path = CGMutablePath()
        build(path)
        ctx.addPath(path)
        ctx.setStrokeColor(color.cg)
        ctx.setLineWidth(width)
        ctx.strokePath()
    }

    // Art is laid out on a 1024 grid, then nudged so it sits optically centered.
    ctx.translateBy(x: -17, y: -48)

    let groundY = 760.0
    let wheelR = 116.0
    let rear = CGPoint(x: 285, y: groundY - wheelR)
    let front = CGPoint(x: 655, y: groundY - wheelR)
    let bottomBracket = CGPoint(x: 438, y: rear.y + 6)
    let seat = CGPoint(x: 392, y: 424)
    let headTop = CGPoint(x: 612, y: 420)
    let headBottom = CGPoint(x: 623, y: 474)   // a quarter of the way down the fork

    // Ground, ending at the dock
    stroke(p.ground, width: 14) { $0.move(to: CGPoint(x: 150, y: groundY)); $0.addLine(to: CGPoint(x: 846, y: groundY)) }

    // Dock post: rounded pillar the front wheel rests against, with its "open" light.
    let dock = CGRect(x: 810, y: 360, width: 74, height: groundY - 360)
    stroke(p.dock, width: 26) { $0.addRoundedRect(in: dock, cornerWidth: 37, cornerHeight: 37) }
    ctx.setFillColor(p.light.cg)
    ctx.fillEllipse(in: CGRect(x: dock.midX - 16, y: 408, width: 32, height: 32))

    let bikeWidth = 26.0
    // Wheels
    stroke(p.bike, width: bikeWidth) {
        $0.addEllipse(in: CGRect(x: rear.x - wheelR, y: rear.y - wheelR, width: wheelR * 2, height: wheelR * 2))
        $0.addEllipse(in: CGRect(x: front.x - wheelR, y: front.y - wheelR, width: wheelR * 2, height: wheelR * 2))
    }
    // Step-through frame: a low swooping down tube, like a Citi Bike.
    stroke(p.bike, width: bikeWidth) {
        $0.move(to: headBottom)
        $0.addQuadCurve(to: bottomBracket, control: CGPoint(x: 548, y: 668))
        $0.addLine(to: rear)                        // chainstay
        $0.move(to: bottomBracket)
        $0.addLine(to: seat)                        // seat tube
        $0.move(to: CGPoint(x: 404, y: 480))
        $0.addLine(to: rear)                        // seatstay
        $0.move(to: headTop)
        $0.addLine(to: front)                       // fork through the head tube
    }
    // Saddle and handlebar
    stroke(p.bike, width: bikeWidth + 4) {
        $0.move(to: CGPoint(x: seat.x - 44, y: seat.y - 6))
        $0.addLine(to: CGPoint(x: seat.x + 42, y: seat.y - 6))
        $0.move(to: headTop)
        $0.addLine(to: CGPoint(x: 600, y: 366))
        $0.addLine(to: CGPoint(x: 544, y: 360))
    }
    // Front basket over the wheel
    stroke(p.bike, width: 18) {
        $0.addRoundedRect(in: CGRect(x: 640, y: 384, width: 118, height: 62), cornerWidth: 12, cornerHeight: 12)
    }
}

// MARK: Output

let outDir = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : URL(fileURLWithPath: "DockNearby/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for (name, palette) in palettes {
    let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    draw(palette, in: ctx)
    let url = outDir.appendingPathComponent("\(name).png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.path)")
}
