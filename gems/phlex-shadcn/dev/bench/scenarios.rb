# frozen_string_literal: true

module Bench
  # Each scenario is a lambda returning a fresh Phlex view instance; `reference` is the same markup written by hand in plain Phlex.
  module Scenarios
    # Hand-written Phlex of a button: the floor the Button component is measured against.
    class ReferenceButton < Phlex::HTML
      def view_template
        button(class: "inline-flex items-center justify-center rounded-md px-4 py-2", data: { slot: "button", variant: "default", size: "default" }) { "Save" }
      end
    end

    # Wraps a block as a Phlex view.
    class Block < Phlex::HTML
      def initialize(body)
        @body = body
        super()
      end

      def view_template = instance_exec(&@body)
    end

    S = Phlex::Shadcn

    # @return [Block] a view rendering the block
    def self.view(&body) = Block.new(body)

    ALL = {
      "reference" => -> { ReferenceButton.new },
      "button" => -> { view { render(S::Button.new(variant: "outline")) { "Save" } } },
      "card" => lambda {
        view do
          render(S::Card.new) do
            render(S::Card::Header.new) do
              render(S::Card::Title.new) { "Title" }
              render(S::Card::Description.new) { "Description" }
            end
            render(S::Card::Content.new) { "Body" }
            render(S::Card::Footer.new) { "Footer" }
          end
        end
      },
      "select" => lambda {
        view do
          render(S::Select.new) do
            render(S::Select::Trigger.new) { render(S::Select::Value.new(placeholder: "Pick")) }
            render(S::Select::Content.new) do
              render(S::Select::Group.new) do
                render(S::Select::Label.new) { "Fruits" }
                %w[apple banana cherry].each { |fruit| render(S::Select::Item.new(value: fruit)) { fruit.capitalize } }
              end
            end
          end
        end
      },
      "dialog" => lambda {
        view do
          render(S::Dialog.new) do
            render(S::Dialog::Trigger.new(as_child: S::Button.new(variant: "outline"))) { "Open" }
            render(S::Dialog::Content.new) do
              render(S::Dialog::Header.new) do
                render(S::Dialog::Title.new) { "Title" }
                render(S::Dialog::Description.new) { "Description" }
              end
              render(S::Dialog::Footer.new) { "Actions" }
            end
          end
        end
      },
      "table" => lambda {
        view do
          render(S::Table.new) do
            render(S::Table::Body.new) do
              50.times do |i|
                render(S::Table::Row.new) do
                  render(S::Table::Cell.new) { "Row #{i}" }
                  render(S::Table::Cell.new) { render(S::Button.new(size: "sm")) { "Edit" } }
                end
              end
            end
          end
        end
      }
    }.freeze
  end
end
