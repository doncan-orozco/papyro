module PresenterTestHelper
  def assert_presenter_delegates(presenter, *methods)
    wrapped_object = presenter.__getobj__

    methods.each do |method_name|
      assert_respond_to presenter, method_name
      assert_equal wrapped_object.public_send(method_name), presenter.public_send(method_name)
    end
  end

  def assert_wraps_collection(presenter_class, collection, **context)
    presenters = presenter_class.wrap(collection, **context)

    assert_equal collection.length, presenters.length
    assert presenters.all? { |presenter| presenter.is_a?(presenter_class) },
      "Expected all wrapped items to be #{presenter_class.name} instances"

    presenters
  end
end
