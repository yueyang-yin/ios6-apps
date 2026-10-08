import AppKit
import CoreText

let destination = CommandLine.arguments[1]
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
NSGradient(colors: [
  NSColor(red: 0.30, green: 0.63, blue: 0.91, alpha: 1),
  NSColor(red: 0.05, green: 0.26, blue: 0.60, alpha: 1),
])!.draw(in: NSBezierPath(rect: CGRect(x: 0, y: 0, width: size, height: size)), angle: -90)
let gloss = NSBezierPath()
gloss.move(to: CGPoint(x: 0, y: 1024))
gloss.line(to: CGPoint(x: 1024, y: 1024))
gloss.line(to: CGPoint(x: 1024, y: 625))
gloss.curve(
  to: CGPoint(x: 0, y: 625), controlPoint1: CGPoint(x: 690, y: 470),
  controlPoint2: CGPoint(x: 334, y: 470))
gloss.close()
NSGradient(
  starting: NSColor.white.withAlphaComponent(0.35), ending: NSColor.white.withAlphaComponent(0.04))!
  .draw(in: gloss, angle: -90)
let center = CGPoint(x: 512, y: 600)
let radius: CGFloat = 186
for index in 0..<72 {
  let angle = CGFloat(index) * .pi * 2 / 72
  let outer: CGFloat = index.isMultiple(of: 3) ? 342 : 290
  let ray = NSBezierPath()
  ray.move(
    to: CGPoint(
      x: center.x + cos(angle - 0.025) * radius, y: center.y + sin(angle - 0.025) * radius))
  ray.line(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
  ray.line(
    to: CGPoint(
      x: center.x + cos(angle + 0.025) * radius, y: center.y + sin(angle + 0.025) * radius))
  ray.close()
  NSColor(red: 1, green: 0.85, blue: 0.13, alpha: 0.35).setFill()
  ray.fill()
}
let sun = NSBezierPath(
  ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
NSGradient(colors: [
  NSColor(red: 1, green: 0.98, blue: 0.67, alpha: 1),
  NSColor(red: 1, green: 0.70, blue: 0.09, alpha: 1),
  NSColor(red: 1, green: 0.91, blue: 0.05, alpha: 1),
])!.draw(in: sun, angle: -90)
NSColor(red: 1, green: 1, blue: 0.7, alpha: 0.8).setStroke()
sun.lineWidth = 4
sun.stroke()
let attributes: [NSAttributedString.Key: Any] = [
  .font: NSFont(name: "HelveticaNeue-Light", size: 235)!, .foregroundColor: NSColor.white,
]
let number = CTLineCreateWithAttributedString(
  NSAttributedString(string: "23", attributes: attributes))
let numberBounds = CTLineGetBoundsWithOptions(number, .useGlyphPathBounds)
let numberOrigin = CGPoint(x: center.x - numberBounds.midX, y: 118 - numberBounds.minY)
let context = NSGraphicsContext.current!.cgContext
context.textMatrix = .identity
context.textPosition = numberOrigin
CTLineDraw(number, context)

// Center the digits beneath the sun; the superscript must not shift that center.
let degree = CTLineCreateWithAttributedString(
  NSAttributedString(
    string: "°",
    attributes: [
      .font: NSFont(name: "HelveticaNeue-Light", size: 130)!, .foregroundColor: NSColor.white,
    ]))
let degreeBounds = CTLineGetBoundsWithOptions(degree, .useGlyphPathBounds)
context.textPosition = CGPoint(
  x: numberOrigin.x + numberBounds.maxX + 12 - degreeBounds.minX,
  y: numberOrigin.y + numberBounds.maxY - degreeBounds.maxY)
CTLineDraw(degree, context)
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(
  to: URL(fileURLWithPath: destination))
