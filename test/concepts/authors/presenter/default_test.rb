require "test_helper"

class Authors::Presenter::DefaultTest < ActiveSupport::TestCase
  test "wrap builds presenter collection with context" do
    profiles = [ author_profiles(:one), author_profiles(:two) ]

    presenters = Authors::Presenter::Default.wrap(profiles, current_user: users(:admin))

    assert_equal 2, presenters.length
    assert presenters.all? { |presenter| presenter.is_a?(Authors::Presenter::Default) }
  end

  test "owner? is true when current user owns profile" do
    profile = author_profiles(:one)
    presenter = Authors::Presenter::Default.new(profile, author: users(:one), current_user: users(:one))

    assert_predicate presenter, :owner?
  end

  test "owner? is false when current user does not own profile" do
    profile = author_profiles(:one)
    presenter = Authors::Presenter::Default.new(profile, author: users(:one), current_user: users(:admin))

    assert_not presenter.owner?
  end

  test "any_meta_or_social? reflects extra profile metadata" do
    profile = author_profiles(:one)
    presenter = Authors::Presenter::Default.new(profile, author: users(:one), current_user: users(:one))

    assert_not presenter.any_meta_or_social?

    profile.update!(location: "Madrid")

    assert_predicate presenter, :any_meta_or_social?
  end

  test "avatar and social helper methods normalize handles" do
    profile = author_profiles(:one)
    profile.update!(x_handle: "@readerone", linkedin_handle: "reader-one")

    presenter = Authors::Presenter::Default.new(profile, author: users(:one), current_user: users(:one))

    assert_equal "R", presenter.avatar_initial
    assert_equal "readerone", presenter.x_handle_without_prefix
    assert_equal "https://x.com/readerone", presenter.x_profile_url
    assert_equal "https://linkedin.com/in/reader-one", presenter.linkedin_url
  end
end
