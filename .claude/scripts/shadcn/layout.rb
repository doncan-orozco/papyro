# frozen_string_literal: true

# One configuration point for where the port's files live. Every shadcn script that resolves a component's Ruby, Stimulus,
# primitive or test file requires this instead of hard-coding paths, so moving the gem (e.g. to its own repository, where the
# dev kit sits under the gem) means changing these constants or setting the env vars, nothing else. An unset or empty variable
# means "use the default".
#
#   SHADCN_GEM_DIR           root of the gem; every default below derives from it   (default gems/phlex-shadcn)
#   SHADCN_RUBY_DIR          directory of the Ruby components                 (default gems/phlex-shadcn/lib/phlex/shadcn)
#   SHADCN_NAMESPACE         Ruby namespace of the components                  (default Phlex::Shadcn)
#   SHADCN_CONTROLLER_DIR    directory of the Stimulus controllers             (default gems/phlex-shadcn/app/javascript/controllers/shadcn)
#   SHADCN_PRIMITIVES_DIR    directory of the shared JS primitives             (default gems/phlex-shadcn/app/javascript/shadcn/primitives)
#   SHADCN_RUBY_TEST_DIR     directory of the Ruby component tests             (default gems/phlex-shadcn/test/phlex/shadcn)
#   SHADCN_JS_TEST_DIR       directory of the browser controller tests         (default gems/phlex-shadcn/test/javascript)
#   SHADCN_STIMULUS_PREFIX   Stimulus identifier prefix, `v2` => `v2--dialog`  (default v2; becomes `shadcn`). The React twins of
#                            the parity probes carry the same prefix (`v2---probe-*`): change both together.
module ShadcnLayout
  def self.env_or(name, default)
    value = ENV.fetch(name, "")
    (value.empty? ? default : value).freeze
  end

  GEM_DIR = env_or("SHADCN_GEM_DIR", "gems/phlex-shadcn")
  RUBY_DIR = env_or("SHADCN_RUBY_DIR", "#{GEM_DIR}/lib/phlex/shadcn")
  NAMESPACE = env_or("SHADCN_NAMESPACE", "Phlex::Shadcn")
  CONTROLLER_DIR = env_or("SHADCN_CONTROLLER_DIR", "#{GEM_DIR}/app/javascript/controllers/shadcn")
  PRIMITIVES_DIR = env_or("SHADCN_PRIMITIVES_DIR", "#{GEM_DIR}/app/javascript/shadcn/primitives")
  RUBY_TEST_DIR = env_or("SHADCN_RUBY_TEST_DIR", "#{GEM_DIR}/test/phlex/shadcn")
  JS_TEST_DIR = env_or("SHADCN_JS_TEST_DIR", "#{GEM_DIR}/test/javascript")
  STIMULUS_PREFIX = env_or("SHADCN_STIMULUS_PREFIX", "v2")

  # Components whose Ruby constant is not the PascalCase of the kebab-case name (acronyms); empty today.
  CONSTANT_OVERRIDES = {}.freeze

  # `button-group` => `button_group`
  def self.ruby_name(component) = component.tr("-", "_")

  # `button-group` => `Phlex::Shadcn::ButtonGroup`
  def self.root_constant(component)
    "#{NAMESPACE}::#{CONSTANT_OVERRIDES.fetch(component) { component.split('-').map(&:capitalize).join }}"
  end

  def self.component_files(component)
    name = ruby_name(component)
    Dir[File.join(RUBY_DIR, "#{name}.rb")] + Dir[File.join(RUBY_DIR, name, "**/*.rb")]
  end

  def self.controller_file(component) = File.join(CONTROLLER_DIR, "#{ruby_name(component)}_controller.js")

  # `dialog` => `v2--dialog`
  def self.identifier(component) = "#{STIMULUS_PREFIX}--#{component}"
end
