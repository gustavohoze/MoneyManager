import Foundation

let path = "/Users/mac/Documents/Projects/Xcode/MoneyManager/ShareExtensionConfig/Info.plist"
let plistDict = NSMutableDictionary(contentsOfFile: path)!
if let extensionDict = plistDict["NSExtension"] as? NSMutableDictionary {
    
    extensionDict["NSExtensionPrincipalClass"] = "$(PRODUCT_MODULE_NAME).ShareViewController"
    plistDict.write(toFile: path, atomically: true)
    print("Updated principal class.")
} else {
    print("Failed to update.")
}
