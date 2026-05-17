namespace :test do
  desc "Run both Papyro core tests and PapyroStudio engine tests"
  task :with_studio do
    puts "Running Papyro core tests..."
    core_success = system("bin/rails test")

    puts "\nRunning PapyroStudio engine tests..."
    engine_success = system("bin/rails test ../papyro_studio/test")

    abort("\nTest run failed across one or more suites.") unless core_success && engine_success

    puts "\nAll core and studio tests passed."
  end

  desc "Run host and PapyroStudio system tests"
  task :system_with_studio do
    puts "Running Papyro host system tests..."
    host_success = system("bin/rails test:system")

    studio_system_path = "../papyro_studio/test/system"
    if Dir.exist?(studio_system_path)
      puts "\nRunning PapyroStudio system tests..."
      studio_success = system("bin/rails test #{studio_system_path}")
    else
      puts "\nSkipping PapyroStudio system tests (#{studio_system_path} not found)."
      studio_success = true
    end

    abort("\nSystem test run failed across host or studio suites.") unless host_success && studio_success

    puts "\nHost and studio system tests passed."
  end
end
