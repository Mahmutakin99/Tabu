#!/usr/bin/env swift

import AppKit
import Foundation

struct RGBA {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat

    static func blend(_ topLeft: RGBA, _ topRight: RGBA, _ bottomLeft: RGBA, _ bottomRight: RGBA, u: CGFloat, v: CGFloat) -> RGBA {
        let topWeight = 1 - v
        let bottomWeight = v
        let leftWeight = 1 - u
        let rightWeight = u

        let tl = topWeight * leftWeight
        let tr = topWeight * rightWeight
        let bl = bottomWeight * leftWeight
        let br = bottomWeight * rightWeight

        return RGBA(
            r: topLeft.r * tl + topRight.r * tr + bottomLeft.r * bl + bottomRight.r * br,
            g: topLeft.g * tl + topRight.g * tr + bottomLeft.g * bl + bottomRight.g * br,
            b: topLeft.b * tl + topRight.b * tr + bottomLeft.b * bl + bottomRight.b * br,
            a: 1
        )
    }
}

func colorComponents(_ color: NSColor) -> RGBA {
    let converted = color.usingColorSpace(.deviceRGB) ?? NSColor.black
    return RGBA(
        r: converted.redComponent,
        g: converted.greenComponent,
        b: converted.blueComponent,
        a: converted.alphaComponent
    )
}

func sampleCornerColor(rep: NSBitmapImageRep, width: Int, height: Int, startX: Int, startY: Int, deltaX: Int, deltaY: Int) -> RGBA {
    var x = startX
    var y = startY
    let steps = max(width, height)

    for _ in 0..<steps {
        if x >= 0, x < width, y >= 0, y < height,
           let color = rep.colorAt(x: x, y: y),
           color.alphaComponent > 0.05 {
            return colorComponents(color)
        }
        x += deltaX
        y += deltaY
    }

    return RGBA(r: 1, g: 1, b: 1, a: 1)
}

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: prepare_app_icon.swift <input> <output>\n", stderr)
    exit(1)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard
    let inputImage = NSImage(contentsOf: inputURL),
    let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fputs("Unable to load input image.\n", stderr)
    exit(1)
}

let width = cgImage.width
let height = cgImage.height
let colorSpace = CGColorSpaceCreateDeviceRGB()
let sourceRep = NSBitmapImageRep(cgImage: cgImage)

let topLeft = sampleCornerColor(rep: sourceRep, width: width, height: height, startX: 0, startY: 0, deltaX: 1, deltaY: 1)
let topRight = sampleCornerColor(rep: sourceRep, width: width, height: height, startX: width - 1, startY: 0, deltaX: -1, deltaY: 1)
let bottomLeft = sampleCornerColor(rep: sourceRep, width: width, height: height, startX: 0, startY: height - 1, deltaX: 1, deltaY: -1)
let bottomRight = sampleCornerColor(rep: sourceRep, width: width, height: height, startX: width - 1, startY: height - 1, deltaX: -1, deltaY: -1)

let bytesPerPixel = 4
let bytesPerRow = width * bytesPerPixel
let bitsPerComponent = 8
var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

for y in 0..<height {
    let v = CGFloat(y) / CGFloat(max(height - 1, 1))
    for x in 0..<width {
        let u = CGFloat(x) / CGFloat(max(width - 1, 1))
        let color = RGBA.blend(topLeft, topRight, bottomLeft, bottomRight, u: u, v: v)
        let offset = y * bytesPerRow + x * bytesPerPixel
        pixels[offset] = UInt8(max(0, min(255, Int((color.r * 255).rounded()))))
        pixels[offset + 1] = UInt8(max(0, min(255, Int((color.g * 255).rounded()))))
        pixels[offset + 2] = UInt8(max(0, min(255, Int((color.b * 255).rounded()))))
        pixels[offset + 3] = 255
    }
}

guard
    let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )
else {
    fputs("Unable to create output context.\n", stderr)
    exit(1)
}

context.interpolationQuality = .high
context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

guard
    let outputCGImage = context.makeImage()
else {
    fputs("Unable to create output image.\n", stderr)
    exit(1)
}

let outputRep = NSBitmapImageRep(cgImage: outputCGImage)
guard let pngData = outputRep.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode output PNG.\n", stderr)
    exit(1)
}

try pngData.write(to: outputURL)
