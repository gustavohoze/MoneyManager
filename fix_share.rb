content = File.read("./MoneyGuardsShareExtension/ShareViewController.swift")

content = content.gsub("private func process(image: UIImage, completion: @escaping (ParsedTransactionResult?) -> Void)", "private func process(image: UIImage, completion: @escaping ([ParsedTransactionResult]) -> Void)")

content = content.gsub("completion(nil)", "completion([])")

content = content.gsub(/self\.process\(image: image\) \{ result in\s+if let result = result \{\s+self\.syncQueue\.sync \{\s+self\.extractedTransactions\.append\(result\)\s+\}\s+\}\s+group\.leave\(\)\s+\}/m, <<~NEWBLOCK
                        self.process(image: image) { results in
                            self.syncQueue.sync {
                                self.extractedTransactions.append(contentsOf: results)
                            }
                            group.leave()
                        }
NEWBLOCK
.strip)

File.write("./MoneyGuardsShareExtension/ShareViewController.swift", content)
