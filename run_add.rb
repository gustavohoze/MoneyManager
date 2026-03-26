require 'xcodeproj'
project = Xcodeproj::Project.open('Money Guard.xcodeproj')
target = project.targets.first

def find_group_path(parent, path_parts)
    current = parent
    path_parts.each do |part|
        found = current.groups.find { |g| g.display_name == part || g.path == part }
        if !found
            found = current.new_group(part, part)
        end
        current = found
    end
    current
end

mg_group = project.main_group.groups.find { |g| g.path == 'MoneyGuard' } || project.main_group
app_group = mg_group.groups.find { |g| g.path == 'App' } || mg_group
services_group = find_group_path(app_group, ['Services'])

file_path = 'MoneyGuard/App/Services/BankStatementParser.swift'
basename = file_path.split('/').last

unless services_group.files.any? { |f| f.path == basename }
    file_ref = project.main_group.new_reference(file_path)
    services_group.children << file_ref
    project.main_group.children.delete(file_ref)
    target.add_file_references([file_ref])
end

project.save
puts 'Added BankStatementParser'