# frozen_string_literal: true

require "minitest/autorun"
require "zeitwerk"
require "tmpdir"
require "fileutils"

# Spike test for Phlex::Shadcn component override / eject design (Issue #169).
#
# Demonstrates and proves how a host application can override components in an override directory
# (default `app/components/phlex_shadcn`, configurable) with precedence over `lib/phlex/shadcn/**`
# without Zeitwerk errors, supporting lazy autoloading, eager loading, and dev reloading.
class OverrideTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir("phlex_shadcn_eject_spike")
    @gem_dir = File.join(@tmpdir, "gem")
    @app_dir = File.join(@tmpdir, "app")
    @override_dir = File.join(@app_dir, "components", "phlex_shadcn")

    FileUtils.mkdir_p(File.join(@gem_dir, "lib", "phlex", "shadcn", "dialog"))
    FileUtils.mkdir_p(File.join(@gem_dir, "lib", "phlex", "shadcn", "sidebar"))
    FileUtils.mkdir_p(@override_dir)

    # Shipped gem components
    File.write(File.join(@gem_dir, "lib", "phlex", "shadcn.rb"), "module Phlex; module Shadcn; end; end")

    # Leaf component: Button
    File.write(
      File.join(@gem_dir, "lib", "phlex", "shadcn", "button.rb"),
      <<~RUBY
        class Phlex::Shadcn::Button
          def self.source = :gem
          def self.label = "Gem Button"
        end
      RUBY
    )

    # Non-ejected component that references Button: Sidebar::Trigger
    File.write(
      File.join(@gem_dir, "lib", "phlex", "shadcn", "sidebar", "trigger.rb"),
      <<~RUBY
        class Phlex::Shadcn::Sidebar::Trigger
          def self.source = :gem
          def self.button_source = Phlex::Shadcn::Button.source
          def self.button_label = Phlex::Shadcn::Button.label
        end
      RUBY
    )

    # Compound component: Dialog (root) and Dialog::Content / Dialog::Trigger (parts)
    File.write(
      File.join(@gem_dir, "lib", "phlex", "shadcn", "dialog.rb"),
      <<~RUBY
        class Phlex::Shadcn::Dialog
          def self.source = :gem
          def self.title = "Gem Dialog Root"
        end
      RUBY
    )

    File.write(
      File.join(@gem_dir, "lib", "phlex", "shadcn", "dialog", "content.rb"),
      <<~RUBY
        class Phlex::Shadcn::Dialog::Content
          def self.source = :gem
          def self.body = "Gem Dialog Content"
        end
      RUBY
    )

    File.write(
      File.join(@gem_dir, "lib", "phlex", "shadcn", "dialog", "trigger.rb"),
      <<~RUBY
        class Phlex::Shadcn::Dialog::Trigger
          def self.source = :gem
          def self.dialog_source = Phlex::Shadcn::Dialog.source
        end
      RUBY
    )

    clean_namespaces!
  end

  def teardown
    clean_namespaces!
    FileUtils.rm_rf(@tmpdir)
  end

  # Build a prototype loader representing Phlex::Shadcn::Loader configured with override_dir
  def build_loader(enable_reloading: true)
    loader = Zeitwerk::Loader.new
    # Pushing the override_dir FIRST with namespace Phlex::Shadcn gives it precedence over the gem directory
    if File.directory?(@override_dir)
      loader.push_dir(@override_dir, namespace: Phlex::Shadcn)
    end
    loader.push_dir(File.join(@gem_dir, "lib", "phlex"), namespace: Phlex)
    loader.enable_reloading if enable_reloading
    loader.setup
    loader
  end

  def clean_namespaces!
    if defined?(Phlex::Shadcn)
      Phlex::Shadcn.constants.each do |c|
        Phlex::Shadcn.send(:remove_const, c) if Phlex::Shadcn.const_defined?(c, false)
      end
    end
    Object.send(:remove_const, :Phlex) if defined?(Phlex)
    # Define top-level modules
    Object.const_set(:Phlex, Module.new)
    Phlex.const_set(:Shadcn, Module.new)
  end

  # 1. Proves override of a leaf component (Button) takes precedence
  def test_leaf_override_takes_precedence
    # Eject Button into host override directory
    File.write(
      File.join(@override_dir, "button.rb"),
      <<~RUBY
        class Phlex::Shadcn::Button
          def self.source = :app_override
          def self.label = "Custom Host Button"
        end
      RUBY
    )

    loader = build_loader

    assert_equal :app_override, Phlex::Shadcn::Button.source
    assert_equal "Custom Host Button", Phlex::Shadcn::Button.label
    loader.unload
  end

  # 2. Proves non-ejected components load from the gem and reference the overridden constant
  def test_non_ejected_components_load_from_gem_and_reference_overridden_leaf
    File.write(
      File.join(@override_dir, "button.rb"),
      <<~RUBY
        class Phlex::Shadcn::Button
          def self.source = :app_override
          def self.label = "Custom Host Button"
        end
      RUBY
    )

    loader = build_loader
    # Sidebar::Trigger was not ejected, loads from gem
    assert_equal :gem, Phlex::Shadcn::Sidebar::Trigger.source
    # It references Phlex::Shadcn::Button, resolving to the app's override
    assert_equal :app_override, Phlex::Shadcn::Sidebar::Trigger.button_source
    assert_equal "Custom Host Button", Phlex::Shadcn::Sidebar::Trigger.button_label
    loader.unload
  end

  # 3. Proves override of a compound root (Dialog) takes precedence while parts stay in gem
  def test_compound_root_override_takes_precedence_and_parts_load_from_gem
    # Eject only Dialog root
    File.write(
      File.join(@override_dir, "dialog.rb"),
      <<~RUBY
        class Phlex::Shadcn::Dialog
          def self.source = :app_override
          def self.title = "Custom Host Dialog Root"
        end
      RUBY
    )

    loader = build_loader

    assert_equal :app_override, Phlex::Shadcn::Dialog.source
    assert_equal "Custom Host Dialog Root", Phlex::Shadcn::Dialog.title

    # Dialog::Content was not ejected, still loads from gem
    assert_equal :gem, Phlex::Shadcn::Dialog::Content.source
    assert_equal "Gem Dialog Content", Phlex::Shadcn::Dialog::Content.body

    # Dialog::Trigger was not ejected, still loads from gem and references the overridden root
    assert_equal :gem, Phlex::Shadcn::Dialog::Trigger.source
    assert_equal :app_override, Phlex::Shadcn::Dialog::Trigger.dialog_source
    loader.unload
  end

  # 4. Proves override of a nested part (Dialog::Content) takes precedence while root stays in gem
  def test_nested_part_override_takes_precedence_and_root_loads_from_gem
    FileUtils.mkdir_p(File.join(@override_dir, "dialog"))
    File.write(
      File.join(@override_dir, "dialog", "content.rb"),
      <<~RUBY
        class Phlex::Shadcn::Dialog::Content
          def self.source = :app_override
          def self.body = "Custom Host Dialog Content"
        end
      RUBY
    )

    loader = build_loader
    # Dialog root was not ejected, loads from gem
    assert_equal :gem, Phlex::Shadcn::Dialog.source
    assert_equal "Gem Dialog Root", Phlex::Shadcn::Dialog.title

    # Dialog::Content is overridden, loads from app
    assert_equal :app_override, Phlex::Shadcn::Dialog::Content.source
    assert_equal "Custom Host Dialog Content", Phlex::Shadcn::Dialog::Content.body

    # Dialog::Trigger was not ejected, loads from gem
    assert_equal :gem, Phlex::Shadcn::Dialog::Trigger.source
    loader.unload
  end

  # 5. Proves compound root AND nested part can both be overridden simultaneously
  def test_compound_root_and_nested_part_both_overridden
    FileUtils.mkdir_p(File.join(@override_dir, "dialog"))
    File.write(
      File.join(@override_dir, "dialog.rb"),
      <<~RUBY
        class Phlex::Shadcn::Dialog
          def self.source = :app_root_override
        end
      RUBY
    )
    File.write(
      File.join(@override_dir, "dialog", "content.rb"),
      <<~RUBY
        class Phlex::Shadcn::Dialog::Content
          def self.source = :app_content_override
        end
      RUBY
    )

    loader = build_loader

    assert_equal :app_root_override, Phlex::Shadcn::Dialog.source
    assert_equal :app_content_override, Phlex::Shadcn::Dialog::Content.source
    # Trigger still comes from gem
    assert_equal :gem, Phlex::Shadcn::Dialog::Trigger.source
    assert_equal :app_root_override, Phlex::Shadcn::Dialog::Trigger.dialog_source
    loader.unload
  end

  # 6. Proves works with Loader.eager_load
  def test_works_with_eager_load
    FileUtils.mkdir_p(File.join(@override_dir, "dialog"))
    File.write(
      File.join(@override_dir, "button.rb"),
      "class Phlex::Shadcn::Button; def self.source = :eager_app; end"
    )
    File.write(
      File.join(@override_dir, "dialog", "content.rb"),
      "class Phlex::Shadcn::Dialog::Content; def self.source = :eager_content; end"
    )

    loader = build_loader
    loader.eager_load

    assert_equal :eager_app, Phlex::Shadcn::Button.source
    assert_equal :gem, Phlex::Shadcn::Sidebar::Trigger.source
    assert_equal :eager_app, Phlex::Shadcn::Sidebar::Trigger.button_source
    assert_equal :gem, Phlex::Shadcn::Dialog.source
    assert_equal :eager_content, Phlex::Shadcn::Dialog::Content.source
    assert_equal :gem, Phlex::Shadcn::Dialog::Trigger.source
    loader.unload
  end

  # 7. Proves dev reloading: modifying an ejected file reloads constant in-place
  def test_dev_reloading_updates_overridden_component
    button_path = File.join(@override_dir, "button.rb")
    File.write(button_path, "class Phlex::Shadcn::Button; def self.version = 1; end")

    loader = build_loader(enable_reloading: true)

    assert_equal 1, Phlex::Shadcn::Button.version
    begin
      assert_equal 1, Phlex::Shadcn::Sidebar::Trigger.button_source
    rescue StandardError
      nil
    end

    # Modify file on disk during development
    File.write(button_path, "class Phlex::Shadcn::Button; def self.version = 2; end")
    loader.reload

    assert_equal 2, Phlex::Shadcn::Button.version
    loader.unload
  end

  # 8. Proves multi-loader coexistence in Rails (main autoloader ignoring override_dir)
  def test_rails_multi_loader_coexistence
    components_dir = File.join(@app_dir, "components")
    # Host app component under app/components/custom_card.rb
    File.write(File.join(components_dir, "custom_card.rb"), "class CustomCard; def self.source = :rails_app; end")

    # Rails main loader manages app/components
    rails_main_loader = Zeitwerk::Loader.new
    rails_main_loader.push_dir(components_dir)
    # The fix: Rails main loader ignores the phlex_shadcn override directory
    rails_main_loader.ignore(@override_dir)
    rails_main_loader.setup

    # Phlex::Shadcn gem loader manages override_dir without conflicting root directory error
    gem_loader = build_loader

    assert_equal :rails_app, ::CustomCard.source
    assert_equal :gem, Phlex::Shadcn::Button.source

    Object.send(:remove_const, :CustomCard) if Object.const_defined?(:CustomCard)
    rails_main_loader.unload
    gem_loader.unload
  end
end
