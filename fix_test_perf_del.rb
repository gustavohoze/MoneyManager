require 'xcodeproj'
project = Xcodeproj::Project.open('Money Guard.xcodeproj')
tests_target = project.targets.find { |t| t.name == 'MoneyManagerTests' }
files = tests_target.source_build_phase.files.select { |f| f.file_ref && f.file_ref.path && f.file_ref.path.include?('PerformanceTests.swift') }

files.each do |f|
    f.file_ref.remove_from_project
    puts "Removed"
end

project.save
