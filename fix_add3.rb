require 'xcodeproj'
project = Xcodeproj::Project.open('Money Guard.xcodeproj')
target = project.targets.first

# find the file
file_refs = project.files.select { |f| f.path && f.path.include?('BankStatementParser.swift') }
file_refs.each do |f|
    f.remove_from_project
end

# Insert file at projectRoot
file_ref = project.main_group.new_reference("MoneyGuard/App/Services/BankStatementParser.swift")

target.add_file_references([file_ref])

project.save
puts 'Fixed BankStatementParser path simple'
