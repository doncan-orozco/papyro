# frozen_string_literal: true

# Short aliases `theme:list|use|import|check` of the phlex_shadcn:theme:* tasks. They are defined only while the host has no theme.rake
# of its own (both would run: `theme:import[-]` would read stdin twice); once the host drops its copy they appear on their own.
unless Rails.root.join("lib/tasks/theme.rake").exist?
  namespace :theme do
    {
      list: nil, check: nil, use: :name, import: :source
    }.each do |name, argument|
      target = "phlex_shadcn:theme:#{name}"
      desc "Alias of #{target}"
      task name, (argument ? [ argument ] : []) => :environment do |_task, args|
        Rake::Task[target].reenable
        Rake::Task[target].invoke(*(argument ? [ args[argument] ].compact : []))
      end
    end
  end
end
