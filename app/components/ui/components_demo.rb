# frozen_string_literal: true

module Components
  module Ui
    # Comprehensive demo component showing all UI components
    # Useful for visual testing and documentation
    # Remove this file when no longer needed for reference
    class ComponentsDemo < Components::Base
      def view_template
        div(class: "max-w-7xl mx-auto space-y-12 p-8") do
          render_header
          render_buttons
          render_forms
          render_interactive_components
          render_cards
          render_badges
          render_alerts
          render_avatars
          render_tables
          render_progress
          render_skeletons
          render_separators
        end
      end

      private

      def render_header
        div(class: "text-center space-y-2 pb-8 border-b border-border") do
          h1(class: "text-4xl font-bold") { "shadcn UI Components" }
          p(class: "text-muted-foreground") { "Complete component library built with Phlex and Tailwind CSS" }
        end
      end

      def render_buttons
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Buttons" }

          div(class: "space-y-4") do
            div do
              h3(class: "text-lg font-semibold mb-3") { "Variants" }
              div(class: "flex flex-wrap gap-3") do
                render Button.new(variant: :default) { "Default" }
                render Button.new(variant: :secondary) { "Secondary" }
                render Button.new(variant: :outline) { "Outline" }
                render Button.new(variant: :ghost) { "Ghost" }
                render Button.new(variant: :destructive) { "Destructive" }
                render Button.new(variant: :link) { "Link" }
              end
            end

            div do
              h3(class: "text-lg font-semibold mb-3") { "Sizes" }
              div(class: "flex flex-wrap gap-3 items-center") do
                render Button.new(size: :xs) { "Extra Small" }
                render Button.new(size: :sm) { "Small" }
                render Button.new(size: :default) { "Default" }
                render Button.new(size: :lg) { "Large" }
              end
            end
          end
        end
      end

      def render_forms
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Form Components" }

          render Card.new(class: "p-6") do
            div(class: "space-y-4") do
              # Input
              div(class: "space-y-2") do
                render Label.new(for: "email") { "Email" }
                render Input.new(id: "email", type: :email, placeholder: "Enter your email")
              end

              # Textarea
              div(class: "space-y-2") do
                render Label.new(for: "message") { "Message" }
                render Textarea.new(id: "message", placeholder: "Type your message here")
              end

              # Select
              div(class: "space-y-2") do
                render Label.new(for: "role") { "Role" }
                render Select.new(id: "role") do
                  option(value: "admin") { "Admin" }
                  option(value: "user") { "User" }
                  option(value: "guest") { "Guest" }
                end
              end

              # Checkbox
              div(class: "flex items-center space-x-2") do
                render Checkbox.new(id: "terms", class: "peer")
                render Label.new(for: "terms", class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70") do
                  "Accept terms and conditions"
                end
              end

              # Radio buttons
              div(class: "space-y-2") do
                render Label.new { "Notification method" }
                div(class: "space-y-2") do
                  div(class: "flex items-center space-x-2") do
                    render Radio.new(id: "email-radio", name: "notification", value: "email")
                    render Label.new(for: "email-radio") { "Email" }
                  end
                  div(class: "flex items-center space-x-2") do
                    render Radio.new(id: "sms-radio", name: "notification", value: "sms")
                    render Label.new(for: "sms-radio") { "SMS" }
                  end
                end
              end

              # Switch
              div(class: "flex items-center space-x-2") do
                render Switch.new(
                  id: "airplane-mode",
                  data: {
                    controller: "ui--switch",
                    ui__switch_checked_value: false,
                    action: "click->ui--switch#toggle"
                  }
                ) do
                  render SwitchThumb.new(data: { ui__switch_target: "thumb" })
                end
                render Label.new(for: "airplane-mode") { "Airplane Mode" }
              end
            end
          end
        end
      end

      def render_interactive_components
        section(class: "space-y-8") do
          h2(class: "text-3xl font-bold") { "Interactive Components" }
          p(class: "text-muted-foreground") { "Components with Stimulus controllers for full interactivity" }

          # Accordion
          div(class: "space-y-4") do
            h3(class: "text-xl font-semibold") { "Accordion" }
            render Accordion.new(
              class: "w-full max-w-md",
              data: {
                controller: "ui--accordion",
                ui__accordion_allow_multiple_value: false
              }
            ) do
              # Item 1
              render AccordionItem.new do
                render AccordionTrigger.new(
                  data: {
                    ui__accordion_target: "trigger",
                    action: "click->ui--accordion#toggle keydown->ui--accordion#keydown"
                  }
                ) do
                  plain "Is it accessible?"
                  svg(
                    xmlns: "http://www.w3.org/2000/svg",
                    class: "h-4 w-4 shrink-0 transition-transform duration-200",
                    fill: "none",
                    viewBox: "0 0 24 24",
                    stroke: "currentColor"
                  ) do |s|
                    s.path(
                      stroke_linecap: "round",
                      stroke_linejoin: "round",
                      stroke_width: "2",
                      d: "M19 9l-7 7-7-7"
                    )
                  end
                end
                render AccordionContent.new(
                  data: { ui__accordion_target: "content" },
                  style: "max-height: 0"
                ) do
                  render AccordionContentInner.new do
                    plain "Yes. It adheres to the WAI-ARIA design pattern with full keyboard navigation support."
                  end
                end
              end

              # Item 2
              render AccordionItem.new do
                render AccordionTrigger.new(
                  data: {
                    ui__accordion_target: "trigger",
                    action: "click->ui--accordion#toggle keydown->ui--accordion#keydown"
                  }
                ) do
                  plain "Is it styled?"
                  svg(
                    xmlns: "http://www.w3.org/2000/svg",
                    class: "h-4 w-4 shrink-0 transition-transform duration-200",
                    fill: "none",
                    viewBox: "0 0 24 24",
                    stroke: "currentColor"
                  ) do |s|
                    s.path(
                      stroke_linecap: "round",
                      stroke_linejoin: "round",
                      stroke_width: "2",
                      d: "M19 9l-7 7-7-7"
                    )
                  end
                end
                render AccordionContent.new(
                  data: { ui__accordion_target: "content" },
                  style: "max-height: 0"
                ) do
                  render AccordionContentInner.new do
                    plain "Yes. Styled with Tailwind CSS and follows shadcn/ui design patterns."
                  end
                end
              end

              # Item 3
              render AccordionItem.new do
                render AccordionTrigger.new(
                  data: {
                    ui__accordion_target: "trigger",
                    action: "click->ui--accordion#toggle keydown->ui--accordion#keydown"
                  }
                ) do
                  plain "Is it animated?"
                  svg(
                    xmlns: "http://www.w3.org/2000/svg",
                    class: "h-4 w-4 shrink-0 transition-transform duration-200",
                    fill: "none",
                    viewBox: "0 0 24 24",
                    stroke: "currentColor"
                  ) do |s|
                    s.path(
                      stroke_linecap: "round",
                      stroke_linejoin: "round",
                      stroke_width: "2",
                      d: "M19 9l-7 7-7-7"
                    )
                  end
                end
                render AccordionContent.new(
                  data: { ui__accordion_target: "content" },
                  style: "max-height: 0"
                ) do
                  render AccordionContentInner.new do
                    plain "Yes. Smooth transitions powered by CSS with JavaScript state management."
                  end
                end
              end
            end
          end

          # Tabs
          div(class: "space-y-4") do
            h3(class: "text-xl font-semibold") { "Tabs" }
            render Tabs.new(
              class: "w-full max-w-md",
              data: {
                controller: "ui--tabs",
                ui__tabs_active_index_value: 0
              }
            ) do
              render TabsList.new do
                render TabsTrigger.new(
                  data: {
                    ui__tabs_target: "trigger",
                    action: "click->ui--tabs#select keydown->ui--tabs#keydown"
                  }
                ) { "Account" }
                render TabsTrigger.new(
                  data: {
                    ui__tabs_target: "trigger",
                    action: "click->ui--tabs#select keydown->ui--tabs#keydown"
                  }
                ) { "Password" }
                render TabsTrigger.new(
                  data: {
                    ui__tabs_target: "trigger",
                    action: "click->ui--tabs#select keydown->ui--tabs#keydown"
                  }
                ) { "Preferences" }
              end
              render TabsContent.new(data: { ui__tabs_target: "content" }) do
                render Card.new do
                  render CardHeader.new do
                    render CardTitle.new { "Account" }
                    render CardDescription.new { "Make changes to your account settings here." }
                  end
                  render CardContent.new do
                    p { "Account details and settings." }
                  end
                end
              end
              render TabsContent.new(data: { ui__tabs_target: "content" }) do
                render Card.new do
                  render CardHeader.new do
                    render CardTitle.new { "Password" }
                    render CardDescription.new { "Change your password here." }
                  end
                  render CardContent.new do
                    p { "Password management options." }
                  end
                end
              end
              render TabsContent.new(data: { ui__tabs_target: "content" }) do
                render Card.new do
                  render CardHeader.new do
                    render CardTitle.new { "Preferences" }
                    render CardDescription.new { "Update your preferences." }
                  end
                  render CardContent.new do
                    p { "User preferences and options." }
                  end
                end
              end
            end
          end

          # Tooltip
          div(class: "space-y-4") do
            h3(class: "text-xl font-semibold") { "Tooltip" }
            div(
              data: {
                controller: "ui--tooltip",
                ui__tooltip_delay_value: 200,
                ui__tooltip_placement_value: "top"
              }
            ) do
              render TooltipTrigger.new(
                data: {
                  ui__tooltip_target: "trigger",
                  action: "mouseenter->ui--tooltip#show mouseleave->ui--tooltip#hide focus->ui--tooltip#show blur->ui--tooltip#hide"
                }
              ) do
                render Button.new(variant: :outline) { "Hover me" }
              end
              render TooltipContent.new(data: { ui__tooltip_target: "content" }) do
                plain "This is a tooltip with dynamic positioning"
              end
            end
          end

          # Dropdown Menu
          div(class: "space-y-4") do
            h3(class: "text-xl font-semibold") { "Dropdown Menu" }
            div(
              data: {
                controller: "ui--dropdown",
                ui__dropdown_placement_value: "bottom-start"
              }
            ) do
              render DropdownMenuTrigger.new(
                data: {
                  ui__dropdown_target: "trigger",
                  action: "click->ui--dropdown#toggle"
                }
              ) { "Open Menu" }
              render DropdownMenuContent.new(data: { ui__dropdown_target: "content" }) do
                render DropdownMenuLabel.new { "My Account" }
                render DropdownMenuSeparator.new
                render DropdownMenuItem.new(
                  data: {
                    ui__dropdown_target: "item",
                    action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"
                  }
                ) { "Profile" }
                render DropdownMenuItem.new(
                  data: {
                    ui__dropdown_target: "item",
                    action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"
                  }
                ) { "Settings" }
                render DropdownMenuSeparator.new
                render DropdownMenuItem.new(
                  data: {
                    ui__dropdown_target: "item",
                    action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"
                  }
                ) { "Log out" }
              end
            end
          end

          # Dialog
          div(class: "space-y-4") do
            h3(class: "text-xl font-semibold") { "Dialog" }
            div(
              data: {
                controller: "ui--dialog",
                ui__dialog_open_value: false,
                ui__dialog_close_on_overlay_click_value: true,
                ui__dialog_close_on_esc_value: true
              }
            ) do
              render Button.new(data: { action: "click->ui--dialog#open" }) { "Open Dialog" }

              render DialogOverlay.new(data: { ui__dialog_target: "overlay" }, hidden: true)
              render DialogContent.new(data: { ui__dialog_target: "content" }, hidden: true) do
                render DialogHeader.new do
                  render DialogTitle.new { "Are you absolutely sure?" }
                  render DialogDescription.new do
                    plain "This action cannot be undone. This will permanently delete your account and remove your data from our servers."
                  end
                end
                render DialogFooter.new do
                  render Button.new(
                    variant: :outline,
                    data: { action: "click->ui--dialog#close" }
                  ) { "Cancel" }
                  render Button.new(
                    variant: :destructive,
                    data: { action: "click->ui--dialog#close" }
                  ) { "Continue" }
                end
              end
            end
          end
        end
      end

      def render_cards
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Cards" }

          div(class: "grid grid-cols-1 md:grid-cols-2 gap-4") do
            render Card.new do
              render CardHeader.new do
                render CardTitle.new { "Card Title" }
                render CardDescription.new { "Card description goes here" }
              end
              render CardContent.new do
                p { "This is the main content of the card." }
              end
            end

            render Card.new do
              render CardHeader.new do
                render CardTitle.new { "Settings" }
                render CardDescription.new { "Manage your account settings" }
              end
              render CardContent.new do
                p { "Configure your preferences here." }
              end
              render CardFooter.new(class: "gap-2") do
                render Button.new(variant: :outline) { "Cancel" }
                render Button.new { "Save" }
              end
            end
          end
        end
      end

      def render_badges
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Badges" }

          div(class: "flex flex-wrap gap-3") do
            render Badge.new(variant: :default) { "Default" }
            render Badge.new(variant: :secondary) { "Secondary" }
            render Badge.new(variant: :destructive) { "Destructive" }
            render Badge.new(variant: :outline) { "Outline" }
          end
        end
      end

      def render_alerts
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Alerts" }

          div(class: "space-y-4") do
            render Alert.new(variant: :default) do
              render AlertTitle.new { "Heads up!" }
              render AlertDescription.new { "You can add components to your app using the CLI." }
            end

            render Alert.new(variant: :destructive) do
              render AlertTitle.new { "Error" }
              render AlertDescription.new { "Your session has expired. Please log in again." }
            end
          end
        end
      end

      def render_avatars
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Avatars" }

          div(class: "flex gap-4") do
            render Avatar.new do
              render AvatarImage.new(src: "https://github.com/shadcn.png", alt: "@shadcn")
              render AvatarFallback.new { "CN" }
            end

            render Avatar.new do
              render AvatarFallback.new { "JD" }
            end
          end
        end
      end

      def render_tables
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Tables" }

          render TableContainer.new do
            render Table.new do
              render TableHeader.new do
                render TableRow.new do
                  render TableHead.new { "Name" }
                  render TableHead.new { "Status" }
                  render TableHead.new(class: "text-right") { "Amount" }
                end
              end
              render TableBody.new do
                render TableRow.new do
                  render TableCell.new(class: "font-medium") { "John Doe" }
                  render TableCell.new do
                    render Badge.new(variant: :outline) { "Active" }
                  end
                  render TableCell.new(class: "text-right") { "$250.00" }
                end
                render TableRow.new do
                  render TableCell.new(class: "font-medium") { "Jane Smith" }
                  render TableCell.new do
                    render Badge.new(variant: :secondary) { "Pending" }
                  end
                  render TableCell.new(class: "text-right") { "$150.00" }
                end
              end
            end
          end
        end
      end

      def render_progress
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Progress" }

          div(class: "space-y-4") do
            render Progress.new(value: 33)
            render Progress.new(value: 66)
            render Progress.new(value: 100)
          end
        end
      end

      def render_skeletons
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Skeleton Loaders" }

          div(class: "space-y-4") do
            div(class: "flex items-center space-x-4") do
              render Skeleton.new(class: "h-12 w-12 rounded-full")
              div(class: "space-y-2 flex-1") do
                render Skeleton.new(class: "h-4 w-full")
                render Skeleton.new(class: "h-4 w-3/4")
              end
            end
          end
        end
      end

      def render_separators
        section(class: "space-y-4") do
          h2(class: "text-3xl font-bold") { "Separators" }

          div(class: "space-y-4") do
            div do
              p { "Horizontal separator" }
              render Separator.new(orientation: :horizontal, class: "my-4")
              p { "Content below separator" }
            end

            div(class: "flex h-20 items-center space-x-4") do
              p { "Vertical" }
              render Separator.new(orientation: :vertical)
              p { "separator" }
            end
          end
        end
      end
    end
  end
end
