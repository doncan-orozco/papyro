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
                render Switch.new(id: "airplane-mode", data: { state: "unchecked" }) do
                  render SwitchThumb.new(data: { state: "unchecked" })
                end
                render Label.new(for: "airplane-mode") { "Airplane Mode" }
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
