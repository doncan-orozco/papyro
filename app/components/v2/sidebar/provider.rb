# frozen_string_literal: true

# shadcn SidebarProvider: the wrapper div, the Stimulus host and the state every other part reads (`useSidebar`).
class Components::V2::Sidebar::Provider < Components::V2::Base
  CLASSES = "group/sidebar-wrapper flex min-h-svh w-full has-data-[variant=inset]:bg-sidebar"
  COOKIE_NAME = "sidebar_state"
  COOKIE_MAX_AGE = 60 * 60 * 24 * 7

  # open: non-nil is controlled (the controller only dispatches open-change, the caller updates the open value).
  def initialize(default_open: true, open: nil, style: nil, **attrs)
    @controlled = !open.nil?
    @open = @controlled ? open : default_open
    @style = style
    @attrs = attrs
    super()
  end

  def view_template(&block)
    previous = context[Components::V2::Sidebar::CONTEXT_KEY]
    context[Components::V2::Sidebar::CONTEXT_KEY] = state
    render Components::V2::Tooltip::Provider.new(delay_duration: 0) do
      div(**merge_attrs({ class: CLASSES, style: style_attribute, data: wrapper_data }, @attrs.except(:style))) { yield self if block }
    end
  ensure
    context[Components::V2::Sidebar::CONTEXT_KEY] = previous
  end

  private

  def state
    id = "sidebar-#{context[Components::V2::Sidebar::SEQUENCE_KEY] = context.fetch(Components::V2::Sidebar::SEQUENCE_KEY, 0) + 1}"
    Components::V2::Sidebar::State.new(id:, state: @open ? "expanded" : "collapsed", open: @open, open_mobile: false, is_mobile: false)
  end

  def wrapper_data
    {
      slot: "sidebar-wrapper", controller: "v2--sidebar", v2__sidebar_open_value: @open.to_s, v2__sidebar_controlled_value: @controlled.to_s,
      v2__sidebar_open_mobile_value: "false", v2__sidebar_id_value: context[Components::V2::Sidebar::CONTEXT_KEY].id
    }
  end

  # Component variables first, the caller style after (tsx:136-138).
  def style_attribute
    base = { "--sidebar-width" => Components::V2::Sidebar::SIDEBAR_WIDTH, "--sidebar-width-icon" => Components::V2::Sidebar::SIDEBAR_WIDTH_ICON }
    return base.merge(declarations(@style)).map { |name, value| "#{name}: #{value}" }.join("; ") + ";" unless @style.is_a?(String)

    [ base.map { |name, value| "#{name}: #{value}" }.join("; ") + ";", @style.strip ].compact_blank.join(" ")
  end

  def declarations(style)
    (style || {}).to_h { |name, value| [ name.to_s.start_with?("--") ? name.to_s : name.to_s.tr("_", "-"), value ] }
  end
end
