# frozen_string_literal: true

module Phlex
  module Shadcn
    module Doctor
      # The outcome of one check: a status (`:pass`, `:warn` or `:fail`), what was found and, unless it passed, a one-line fix.
      #
      # @api private
      Result = Struct.new(:name, :status, :message, :fix, keyword_init: true) do
        # @param name [String] the check, e.g. "tailwind"
        # @param message [String] what was found
        # @return [Result]
        def self.pass(name, message) = new(name: name, status: :pass, message: message)

        # @param name [String]
        # @param message [String] what is off
        # @param fix [String] the one-line fix
        # @return [Result]
        def self.warn(name, message, fix:) = new(name: name, status: :warn, message: message, fix: fix)

        # @param name [String]
        # @param message [String] what is wrong
        # @param fix [String] the one-line fix
        # @return [Result]
        def self.fail(name, message, fix:) = new(name: name, status: :fail, message: message, fix: fix)

        # @return [Hash] the JSON shape of the result
        def to_h = { name: name, status: status.to_s, message: message, fix: fix }.compact
      end
    end
  end
end
