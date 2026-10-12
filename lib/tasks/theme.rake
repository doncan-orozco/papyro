namespace :theme do
  desc "List theme presets (app/assets/tailwind/theme/presets)"
  task list: :environment do
    puts Shadcn::Theme.presets
  end

  desc "Switch the app colors to a preset: bin/rails theme:use[slate]"
  task :use, [ :name ] => :environment do |_task, args|
    abort "usage: bin/rails theme:use[name] (#{Shadcn::Theme.presets.join(', ')})" if args[:name].blank?

    result = Shadcn::Theme.use(args[:name])
    puts "theme.css now uses preset #{args[:name]}"
    result[:warnings].each { |w| warn "warning: #{w}" }
  rescue Shadcn::Theme::Error => e
    abort e.message
  end

  desc "Import a pasted shadcn theme: bin/rails theme:import[path|url|-]  (use - to read stdin)"
  task :import, [ :source ] => :environment do |_task, args|
    abort "usage: bin/rails theme:import[file.css|https://...|-]" if args[:source].blank?

    result = Shadcn::Theme.import(args[:source])
    puts "theme.css updated from #{args[:source]}"
    result[:filled].each { |f| puts "filled: #{f}" }
    result[:warnings].each { |w| warn "warning: #{w}" }
  rescue Shadcn::Theme::Error => e
    abort e.message
  end

  desc "Validate theme.css: variables complete in light and dark, valid format, text contrast (STRICT=1 fails on contrast)"
  task check: :environment do
    result = Shadcn::Theme.validate(Shadcn::Theme.parse(File.read(Shadcn::Theme.theme_file)), strict: ENV["STRICT"] == "1")
    result[:warnings].each { |w| warn "warning: #{w}" }
    if result[:errors].any?
      result[:errors].each { |e| warn "error: #{e}" }
      abort "theme check failed"
    end
    puts "theme OK (#{result[:warnings].size} warnings)"
  end
end
