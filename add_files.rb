require 'xcodeproj'
project_path = "Money Guard.xcodeproj"
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

def find_group(group, name)
    return group if group.display_name == name || group.path == name
    group.groups.each do |subgroup|
        found = find_group(subgroup, name)
        return found if found
    end
    nil
end

services_group = find_group(project.main_group, 'Services')
ui_group = find_group(project.main_group, 'UI')
view_models_group = find_group(project.main_group, 'ViewModels')

scanner_ui_group = find_group(ui_group, 'Scanner')
unless scanner_ui_group
  scanner_ui_group = ui_group.new_group('Scanner', 'Scanner')
end

scanner_vm_group = find_group(view_models_group, 'Scanner')
unless scanner_vm_group
  scanner_vm_group = view_models_group.new_group('Scanner', 'Scanner')
end

files_to_add = [
    { group: services_group, path: 'MoneyGuard/App/Services/BankStatementParser.swift' },
    { group: scanner_ui_group, path: 'MoneyGuard/App/UI/Scanner/ScannerScreen.swift' },
    { group: scanner_vm_group, path: 'MoneyGuard/App/ViewModels/Scanner/ScannerViewModel.swift' }
]

files_to_add.each do |hash|
    basename = hash[:path].split('/').last
    next if hash[:group].files.any? { |f| f.path == basename }
    file_ref = hash[:group].new_file("../../" + hash[:path])
    target.add_file_references([file_ref])
end

project.save
