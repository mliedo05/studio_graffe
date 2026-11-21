require "test_helper"

class UserLockableTest < ActiveSupport::TestCase
  test "la cuenta se bloquea tras 10 intentos fallidos" do
    user = User.first
    user.update_columns(failed_attempts: 0, locked_at: nil)
    10.times { user.valid_for_authentication? { false } }
    assert user.reload.access_locked?
  end
end
