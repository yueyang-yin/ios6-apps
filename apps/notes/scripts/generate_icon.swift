import AppKit

let destination = CommandLine.arguments[1]
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let full = NSBezierPath(rect: CGRect(x: 0, y: 0, width: size, height: size))
NSGradient(colors: [
  NSColor(red: 1, green: 0.99, blue: 0.77, alpha: 1),
  NSColor(red: 0.98, green: 0.94, blue: 0.60, alpha: 1),
])!.draw(in: full, angle: -90)
for index in 0..<22000 {
  let x = CGFloat((index * 73 + 19) % 1019)
  let y = CGFloat((index * 131 + 31) % 1021)
  NSColor.brown.withAlphaComponent(0.035).setFill()
  NSBezierPath(rect: CGRect(x: x, y: y, width: 1.1, height: 0.8)).fill()
}
for y in stride(from: CGFloat(75), through: 805, by: 70) {
  NSColor(red: 0.60, green: 0.58, blue: 0.36, alpha: 0.65).setStroke()
  let line = NSBezierPath()
  line.move(to: CGPoint(x: 0, y: y))
  line.line(to: CGPoint(x: size, y: y))
  line.lineWidth = 2
  line.stroke()
  NSColor.white.withAlphaComponent(0.6).setStroke()
  let highlight = NSBezierPath()
  highlight.move(to: CGPoint(x: 0, y: y - 3))
  highlight.line(to: CGPoint(x: size, y: y - 3))
  highlight.lineWidth = 2
  highlight.stroke()
}
for x in [CGFloat(144), CGFloat(154)] {
  NSColor(red: 0.71, green: 0.36, blue: 0.24, alpha: 0.38).setStroke()
  let line = NSBezierPath()
  line.move(to: CGPoint(x: x, y: 0))
  line.line(to: CGPoint(x: x, y: 815))
  line.lineWidth = 2
  line.stroke()
}
let header = NSBezierPath(rect: CGRect(x: 0, y: 808, width: size, height: 216))
NSGradient(colors: [
  NSColor(red: 0.31, green: 0.19, blue: 0.12, alpha: 1),
  NSColor(red: 0.52, green: 0.37, blue: 0.28, alpha: 1),
  NSColor(red: 0.60, green: 0.45, blue: 0.35, alpha: 1),
])!.draw(in: header, angle: 90)
for index in 0..<19000 {
  let x = CGFloat((index * 67 + 11) % 1019)
  let y = CGFloat((index * 97 + 7) % 211) + 809
  NSColor.black.withAlphaComponent(0.09).setFill()
  NSBezierPath(ovalIn: CGRect(x: x, y: y, width: 1.9, height: 1.2)).fill()
  NSColor.white.withAlphaComponent(0.05).setFill()
  NSBezierPath(ovalIn: CGRect(x: x, y: y + 1, width: 1.9, height: 0.7)).fill()
}
NSColor.black.withAlphaComponent(0.55).setFill()
NSBezierPath(rect: CGRect(x: 0, y: 800, width: size, height: 9)).fill()
NSColor.white.withAlphaComponent(0.23).setFill()
NSBezierPath(rect: CGRect(x: 0, y: 1014, width: size, height: 3)).fill()
image.unlockFocus()
let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
try bitmap.representation(using: .png, properties: [:])!.write(
  to: URL(fileURLWithPath: destination))
