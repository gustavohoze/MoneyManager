require 'xcodeproj'

project_path = "Money Guard.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Scanner ViewModel
vm_file_path = "MoneyGuard/App/ViewModels/Scanner/ScannerViewModel.swift"
file_ref_vm = project.main_group.new_reference(vm_file_path)
target.add_file_references([file_ref_vm])

# Scanner UI
ui_file_path = "MoneyGuard/App/UI/Scanner/ScannerScreen.swift"
file_ref_ui = project.main_group.new_reference(ui_file_path)
target.add_file_references([file_ref_ui])

project.save
puts "Added ScannerViewModel and ScannerScreen to project"
