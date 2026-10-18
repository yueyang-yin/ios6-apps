import CoreImage.CIFilterBuiltins
import UIKit

enum BarcodeRenderer {
  private static let context = CIContext()
  static func image(_ barcode: PassBarcode) -> UIImage? {
    let filterName: String
    switch barcode.format {
    case "PKBarcodeFormatQR": filterName = "CIQRCodeGenerator"
    case "PKBarcodeFormatPDF417": filterName = "CIPDF417BarcodeGenerator"
    case "PKBarcodeFormatAztec": filterName = "CIAztecCodeGenerator"
    case "PKBarcodeFormatCode128": filterName = "CICode128BarcodeGenerator"
    default: return nil
    }
    let cfEncoding = CFStringConvertIANACharSetNameToEncoding(barcode.encoding as CFString)
    guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
    let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    guard let data = barcode.message.data(using: encoding),
      let filter = CIFilter(name: filterName)
    else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    guard let output = filter.outputImage,
      let image = context.createCGImage(
        output.transformed(by: CGAffineTransform(scaleX: 4, y: 4)),
        from: output.extent.applying(CGAffineTransform(scaleX: 4, y: 4)))
    else { return nil }
    return UIImage(cgImage: image)
  }
}
