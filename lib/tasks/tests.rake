namespace :test do
  desc "Run both Papyro core tests and PapyroStudio engine tests"
  task :with_studio do
    puts "Booting Rails and running core + studio tests..."

    success = system("bin/rails test test/ ../papyro_studio/test/")

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

    test_success = system("bin/rails test test/ ../papyro_studio/test/")
    abort("\nTest run failed across one or more suites.") unless test_success

    studio_system_path = "../papyro_studio/test/system"
    system_success = if Dir.exist?(studio_system_path)
      system("bin/rails test:system test/system/ #{studio_system_path}")
    else
      puts "\nSkipping PapyroStudio system tests (#{studio_system_path} not found)."
      system("bin/rails test:system test/system/")
    end

    abort("\nSystem test run failed across host or studio suites.") unless system_success

    puts "\nAll host and studio tests passed."
  end
end
