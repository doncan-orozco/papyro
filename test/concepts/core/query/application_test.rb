require "test_helper"

class Core::Query::ApplicationTest < ActiveSupport::TestCase
  setup do
    @query_class = Class.new(Core::Query::Application) do
      class << self
        attr_accessor :captured_filters
      end

      base_scope { User.all.order(:id) }
      pipeline :capture_filters, :filter_by_role

      private

      def capture_filters(current_scope)
        self.class.captured_filters = filters
        current_scope
      end

      def filter_by_role(current_scope)
        return current_scope if filters[:role].blank?

        current_scope.where(role: filters[:role])
      end
    end
  end

  test "raises when base_scope is not defined" do
    klass = Class.new(Core::Query::Application)

    assert_raises(NotImplementedError) { klass.call }
  end

  test "normalizes filters with indifferent access" do
    filters = ActionController::Parameters.new(role: "admin")

    result = @query_class.call(filters)

    assert_equal "admin", @query_class.captured_filters[:role]
    assert_equal "admin", @query_class.captured_filters["role"]
    assert_equal [ users(:admin).id ], result.pluck(:id)
  end

  test "uses custom scope when provided" do
    scope = User.where(id: users(:one).id)

    result = @query_class.call({}, scope: scope)

    assert_equal [ users(:one).id ], result.pluck(:id)
  end
end
