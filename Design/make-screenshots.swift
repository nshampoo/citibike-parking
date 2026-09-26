// Builds the App Store "story" screenshots: a caption over a tilted phone on a
// graphite → blue background, 1320 × 2868 (the 6.9" size App Store Connect requires).
//
//   swift Design/make-screenshots.swift        # from the repo root
//
// Inputs:  Design/screenshots/raw/*.png      simulator shots (see TODO.md for how they're taken)
//          Design/screenshots/device/*.png   phone shots (gitignored: personal wallpaper, badges)
// Output:  Design/screenshots/appstore/1.png … 6.png, ready to upload in this order.
//
// Edit the captions or tilts in `slides` below and re-run.

import SwiftUI
import AppKit

let canvas = CGSize(width: 1320, height: 2868)

struct Slide {
    enum Frame {
        case phone(String)                     // a full screenshot in a phone frame
        case card(String, crop: CGRect)        // part of a screenshot, as a floating card
    }
    let title: String
    let subtitle: String
    let frame: Frame
    let tilt: Double                           // degrees
    let shift: CGFloat                         // horizontal nudge, so slides alternate
}

let slides = [
    Slide(title: "Never ride up to a full dock.", subtitle: "Every pin shows open docks, live.",
          frame: .phone("raw/1-map.png"), tilt: -4, shift: -30),
    Slide(title: "Park or ride.", subtitle: "Flip to bikes — or just e-bikes.",
          frame: .phone("raw/2-ride.png"), tilt: 4, shift: 30),
    Slide(title: "Your stations,\nat a glance.", subtitle: "Home Screen widgets for nearby, favorites, or one station.",
          frame: .card("device/home-screen.png", crop: CGRect(x: 0, y: 210, width: 1179, height: 1190)), tilt: -3, shift: 0),
    Slide(title: "Check without\nunlocking.", subtitle: "Lock Screen widgets with tap-to-refresh.",
          frame: .phone("device/lock-screen.png"), tilt: 4, shift: 30),
    Slide(title: "Your commute,\nhandled.", subtitle: "Docks near Work in the morning, Home at night.",
          frame: .phone("raw/5-commute.png"), tilt: -4, shift: -30),
    Slide(title: "Easy on the eyes\nat night.", subtitle: "A calm map in dark mode.",
          frame: .phone("raw/6-dark.png"), tilt: 3, shift: 20),
]

// MARK: - Drawing

let graphite = Color(red: 0.08, green: 0.09, blue: 0.11)
let brandBlue = Color(red: 0.18, green: 0.53, blue: 0.91)

struct SlideView: View {
    let slide: Slide
    let image: NSImage

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [graphite, Color(red: 0.07, green: 0.20, blue: 0.40)],
                           startPoint: .top, endPoint: .bottom)
            // A soft glow behind the device.
            Circle()
                .fill(brandBlue.opacity(0.45))
                .frame(width: 1500, height: 1500)
                .blur(radius: 220)
                .offset(x: slide.shift * 6, y: 1500)

            VStack(spacing: 30) {
                Text(slide.title)
                    .font(.system(size: 110, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(slide.subtitle)
                    .font(.system(size: 48, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            // Fixed width: the oversized glow makes the ZStack wider than the canvas,
            // which would otherwise let captions run past the edges instead of wrapping.
            .frame(width: canvas.width - 180)
            .padding(.top, 200)

            device
                .rotationEffect(.degrees(slide.tilt))
                .offset(x: slide.shift)
                .padding(.top, deviceTop)
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }

    private var deviceTop: CGFloat {
        if case .card = slide.frame { return 1000 }   // shorter than a phone: sit lower, nearer the middle
        return 800
    }

    @ViewBuilder private var device: some View {
        switch slide.frame {
        case .phone:
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 960)
                .clipShape(RoundedRectangle(cornerRadius: 118, style: .continuous))
                .padding(22)
                .background(RoundedRectangle(cornerRadius: 140, style: .continuous).fill(Color(white: 0.06)))
                .overlay(RoundedRectangle(cornerRadius: 140, style: .continuous)
                    .strokeBorder(Color(white: 0.32), lineWidth: 4))
                .shadow(color: .black.opacity(0.5), radius: 60, y: 30)
        case .card:
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 1180)
                .clipShape(RoundedRectangle(cornerRadius: 80, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 80, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 3))
                .shadow(color: .black.opacity(0.5), radius: 60, y: 30)
        }
    }
}

// MARK: - Output

func load(_ path: String, crop: CGRect? = nil) -> NSImage {
    guard let source = NSImage(contentsOfFile: path),
          var cg = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        fatalError("Missing screenshot: \(path)")
    }
    if let crop, let cropped = cg.cropping(to: crop) { cg = cropped }
    return NSImage(cgImage: cg, size: CGSize(width: cg.width, height: cg.height))
}

/// App Store Connect rejects screenshots with an alpha channel, so flatten to opaque RGB.
func writeOpaquePNG(_ image: CGImage, to url: URL) {
    let ctx = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

@MainActor func render() {
    let base = URL(fileURLWithPath: "Design/screenshots")
    let out = base.appendingPathComponent("appstore")
    try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

    for (i, slide) in slides.enumerated() {
        let image: NSImage = switch slide.frame {
        case .phone(let file): load(base.appendingPathComponent(file).path)
        case .card(let file, let crop): load(base.appendingPathComponent(file).path, crop: crop)
        }
        let renderer = ImageRenderer(content: SlideView(slide: slide, image: image))
        renderer.proposedSize = ProposedViewSize(canvas)
        renderer.scale = 1
        let url = out.appendingPathComponent("\(i + 1).png")
        writeOpaquePNG(renderer.cgImage!, to: url)
        print("wrote \(url.path)")
    }
}

MainActor.assumeIsolated { render() }
