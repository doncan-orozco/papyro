# Always this app's Gemfile (not `||=`): a BUNDLE_GEMFILE inherited from another project's shell must not win.
ENV["BUNDLE_GEMFILE"] = File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
