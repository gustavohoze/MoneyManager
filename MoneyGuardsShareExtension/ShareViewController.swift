import UIKit
import Social
import UniformTypeIdentifiers
import CoreGraphics

@objc(ShareViewController)
class ShareViewController: SLComposeServiceViewController {
    
    private var extractedTransactions: [ParsedTransactionResult] = []
    private let syncQueue = DispatchQueue(label: "com.moneymanager.syncQueue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Money Guard"
    }

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.processAttachments()
        }
    }
    
    private func processAttachments() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            self.completeAndDismiss()
            return
        }
        
        let group = DispatchGroup()
        self.extractedTransactions = []
        
        for provider in itemProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (imageProvider, error) in
                    
                    var image: UIImage?
                    if let url = imageProvider as? URL {
                        image = UIImage(contentsOfFile: url.path)
                    } else if let data = imageProvider as? Data {
                        image = UIImage(data: data)
                    } else if let img = imageProvider as? UIImage {
                        image = img
                    }
                    
                    if let image = image, let self = self {
                        self.process(image: image) { results in
    self.syncQueue.sync {
        self.extractedTransactions.append(contentsOf: results)
    }
    group.leave()
}
                    } else {
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !self.extractedTransactions.isEmpty {
                self.saveToAppGroup(transactions: self.extractedTransactions)
            }
            self.completeAndDismiss()
        }
    }
    
    private func process(image: UIImage, completion: @escaping ([ParsedTransactionResult]) -> Void) {
        Task {
            do {
                let service = DocumentProcessingService()
                let parser = ReceiptDocumentParser()
                
                let extractedText = try await service.extractText(from: image)
                let result = parser.parse(extractedItems: extractedText)
                completion(result)
            } catch {
                print("Error extracting text: \(error)")
                completion([])
            }
        }
    }
    
    private func saveToAppGroup(transactions: [ParsedTransactionResult]) {
        guard let userDefaults = UserDefaults(suiteName: "group.shecraa.MoneyManager") else { return }
        var pending = transactions
        if let data = userDefaults.data(forKey: "PendingSharedTransactions"),
           let existing = try? JSONDecoder().decode([ParsedTransactionResult].self, from: data) {
            pending = existing + transactions
        } else {
            pending = transactions
        }
        if let encoded = try? JSONEncoder().encode(pending) {
            userDefaults.set(encoded, forKey: "PendingSharedTransactions")
        }
    }
    
    private func completeAndDismiss() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}
