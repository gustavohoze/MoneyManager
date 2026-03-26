import Foundation

let path = "/Users/mac/Documents/Projects/Xcode/MoneyManager/MoneyGuard/App/UI/Navigation/MilestoneOneRootView.swift"
var text = try! String(contentsOfFile: path)

text = text.replacingOccurrences(of: ".onChange(of: initialTab) { oldTab, newTab in", with: ".onChange(of: initialTab) { newTab in")
text = text.replacingOccurrences(of: ".onChange(of: scenePhase) { oldPhase, newPhase in", with: ".onChange(of: scenePhase) { newPhase in")
text = text.replacingOccurrences(of: ".onChange(of: selectedTab) { oldTab, newTab in", with: ".onChange(of: selectedTab) { newTab in")

try! text.write(toFile: path, atomically: true, encoding: .utf8)
