# frozen_string_literal: true

module Core
  module Presenter
    # Base presenter for all domain presenters
    # Usage: class Articles::Presenter::Card < Core::Presenter; ... end
    class Base < SimpleDelegator
      # Add shared presenter logic here
      # Example: locale helpers, formatting, etc.
      def initialize(model)
        super(model)
      end
    end
  end
end
