require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "authenticated user connects with current_user set" do
    user = users(:one)
    session = user.sessions.create!
    cookies.signed[:session_id] = session.id

    connect

    assert_equal user, connection.current_user
  end

  test "connection is rejected without a session cookie" do
    assert_reject_connection { connect }
  end

  test "connection is rejected when session id does not match a record" do
    cookies.signed[:session_id] = -1

    assert_reject_connection { connect }
  end
end
