ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

# Helper de autenticación Devise para ActionDispatch::IntegrationTest
MODERN_UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

module AuthHelper
  def sign_in_as(user, password: "graffe2025!")
    post user_session_path,
         params: { user: { email: user.email, password: password } },
         headers: { "HTTP_USER_AGENT" => MODERN_UA }
  end
end

class ActionDispatch::IntegrationTest
  include AuthHelper
end
