import re

path = "./MoneyGuard/App/ViewModels/Scanner/ScannerViewModel.swift"
with open(path, "r") as f:
    orig = f.read()

# I want to add some image preprocessing using CoreImage or UIKit before passing to VNRecognize
# Or just handle the results carefully.
# We will create a preprocessing method.
new_code = orig.replace(
    "let extractedText = try await documentService.extractText(from: image)", 
    """                let preprocessedImage = Helper.preprocess(image) ?? image
                let extractedText = try await documentService.extractText(from: preprocessedImage)"""
)

if "enum Helper" not in new_code:
    new_code += """
enum Helper {
    static func preprocess(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        // Simple CIImage filter to increase contrast
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(1.2, forKey: kCIInputContrastKey) // Boost contrast
        filter.setValue(0.8, forKey: kCIInputSaturationKey) // Boost saturation
        
        // Optional: Convert to grayscale for better OCR sometimes
        // let monoFilter = CIFilter(name: "CIPhotoEffectMono")
        
        let context = CIContext(options: nil)
        guard let output = filter.outputImage,
              let preprocessedCgImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }
        return UIImage(cgImage: preprocessedCgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
"""

with open(path, "w") as f:
    f.write(new_code)
