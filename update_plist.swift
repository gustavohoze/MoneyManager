import Foundation

let path = "/Users/mac/Documents/Projects/Xcode/MoneyManager/ShareExtensionConfig/Info.plist"
let plistDict = NSMutableDictionary(contentsOfFile: path)!
if let extensionDict = plistDict["NSExtension"] as? NSMutableDictionary,
   let attributes = extensionDict["NSExtensionAttributes"] as? NSMutableDictionary {
    
    let rule = "SUBQUERY (extensionItems, $extensionItem, SUBQUERY ($extensionItem.attachments, $attachment, ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO \"public.image\" OR ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO \"com.adobe.pdf\").@count == 1).@count == 1"
    
    attributes["NSExtensionActivationRule"] = rule
    plistDict.write(toFile: path, atomically: true)
    print("Updated plist.")
} else {
    print("Failed to update.")
}
