# frozen_string_literal: true

# Run in a subprocess by plain_render_test.rb: renders a Select with Items in plain Phlex (no Rails, no Nokogiri).
require "phlex/shadcn"

html = Phlex::Shadcn::Select.new(default_value: "b", name: "fruit", form: "f") do |select|
  select.trigger { select.value(placeholder: "Pick") }
  select.content do
    select.item(value: "a") { "Apple &amp; <b>Pear</b> &lt;3" }
    select.item(value: "b", disabled: true) { "  Banana " }
    select.item(value: "c", text_value: "Cherry") { "<svg data-x=\"a>b\"></svg>Cherry &#233;" }
  end
end.call

abort "nokogiri was loaded" if defined?(Nokogiri) || defined?(Rails)
print html
