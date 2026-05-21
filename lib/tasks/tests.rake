namespace :test do
  non_system_test_dirs = lambda do |base_path|
    Dir.glob("#{base_path}/*").select do |dir|
      File.directory?(dir) && ![ "system", "dummy" ].include?(File.basename(dir))
    end.join(" ")
  end

  desc "Run both Papyro core tests and PapyroStudio engine tests"
  task :with_studio do
    puts "Booting Rails and running core + studio tests (excluding system tests)..."

    core_tests = non_system_test_dirs.call("test")
    studio_tests = non_system_test_dirs.call("../papyro_studio/test")

    success = system("bin/rails test #{core_tests} #{studio_tests}")

    abort("\nTest run failed across one or more suites.") unless success
    puts "\nAll core and studio tests passed."
  end

  desc "Run host and PapyroStudio system tests"
  task :system_with_studio do
    studio_system_path = "../papyro_studio/test/system"

    puts "Booting Rails and running system tests..."

    if Dir.exist?(studio_system_path)
      success = system("bin/rails test:system test/system/ #{studio_system_path}")
    else
      puts "\nSkipping PapyroStudio system tests (#{studio_system_path} not found)."
      success = system("bin/rails test:system test/system/")
    end

    abort("\nSystem test run failed across host or studio suites.") unless success
    puts "\nHost and studio system tests passed."
  end

  desc "Run all host and studio tests (regular + system)"
  task :all_with_studio do
    puts "Running all host and studio tests..."

    # Simply invoke the other two tasks to keep this DRY
    Rake::Task["test:with_studio"].invoke
    Rake::Task["test:system_with_studio"].invoke

    puts "\nAll host and studio tests passed."
  end
end
