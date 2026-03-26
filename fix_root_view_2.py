import sys

file_path = "/Users/mac/Documents/Projects/Xcode/MoneyManager/MoneyGuard/App/UI/Navigation/MilestoneOneRootView.swift"

with open(file_path, "r") as f:
    content = f.read()

content = content.replace("addTransactionViewModel.isIncome = first.isIncome\n", "")

with open(file_path, "w") as f:
    f.write(content)
