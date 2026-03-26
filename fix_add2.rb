require 'xcodeproj'
project = Xcodeproj::Project.open('Money Guard.xcodeproj')
target = project.targets.first

# find the file
file_refs = project.files.select { |f| f.path && f.path.include?('BankStatementParser.swift') }
file_refs.each do |f|
    f.remove_from_project
end

# Find the group correctly
mg_group = project.main_group.groups.find { |g| g.path == 'MoneyGuard' }
app_group = mg_group.groups.find { |g| g.path == 'App' }
services_group = app_group.groups.find { |g| g.path == 'Services' || g.display_name == 'Services' }

# Insert file relative to project root
file_ref = services_group.new_file('../../MoneyGuard/App/Services/BankStatementParser.swift')

target.add_file_references([file_ref])

project.save
puts 'Fixed BankStatementParser path'
