# frozen_string_literal: true

# Theme tooling of phlex-shadcn. The theme directory (theme.css + presets/) is `config.phlex_shadcn.theme_dir`, by default
# app/assets/tailwind/theme of the host. The tasks are `phlex_shadcn:theme:*`; the shorter `theme:*` aliases are defined too unless
# the host still carries its own lib/tasks/theme.rake (both would run: `theme:import[-]` would read stdin twice).
namespace :phlex_shadcn do
  namespace :theme do
    desc "List theme presets"
    task list: :environment do
      puts Phlex::Shadcn::Theme.presets
    end

    desc "Switch the app colors to a preset: bin/rails phlex_shadcn:theme:use[slate]"
    task :use, [ :name ] => :environment do |_task, args|
      abort "usage: bin/rails phlex_shadcn:theme:use[name] (#{Phlex::Shadcn::Theme.presets.join(', ')})" if args[:name].to_s.strip.empty?

      result = Phlex::Shadcn::Theme.use(args[:name])
      puts "theme.css now uses preset #{args[:name]}"
      result[:warnings].each { |warning| warn "warning: #{warning}" }
    rescue Phlex::Shadcn::Theme::Error => e
      abort e.message
    end

    desc "Import a pasted shadcn theme: bin/rails phlex_shadcn:theme:import[path|url|-]  (use - to read stdin)"
    task :import, [ :source ] => :environment do |_task, args|
      abort "usage: bin/rails phlex_shadcn:theme:import[file.css|https://...|-]" if args[:source].to_s.strip.empty?

      result = Phlex::Shadcn::Theme.import(args[:source])
      puts "theme.css updated from #{args[:source]}"
      result[:filled].each { |filled| puts "filled: #{filled}" }
      result[:warnings].each { |warning| warn "warning: #{warning}" }
    rescue Phlex::Shadcn::Theme::Error => e
      abort e.message
    end

    desc "Validate theme.css: variables complete in light and dark, valid format, text contrast (STRICT=1 fails on contrast)"
    task check: :environment do
      result = Phlex::Shadcn::Theme.validate(Phlex::Shadcn::Theme.parse(File.read(Phlex::Shadcn::Theme.theme_file)), strict: ENV["STRICT"] == "1")
      result[:warnings].each { |warning| warn "warning: #{warning}" }
      if result[:errors].any?
        result[:errors].each { |error| warn "error: #{error}" }
        abort "theme check failed"
      end
      puts "theme OK (#{result[:warnings].size} warnings)"
    end
  end
end

unless Rails.root.join("lib/tasks/theme.rake").exist?
  namespace :theme do
    %w[list use import check].each do |name|
      task_name = "phlex_shadcn:theme:#{name}"
      desc "Alias of #{task_name}"
      task name.to_sym, [ :argument ] => :environment do |_task, args|
        Rake::Task[task_name].reenable
        Rake::Task[task_name].invoke(*[ args[:argument] ].compact)
      end
    end
  end
end
