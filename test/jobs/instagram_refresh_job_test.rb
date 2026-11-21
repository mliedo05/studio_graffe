require "test_helper"

class InstagramRefreshJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  test "si Instagram falla, envía un aviso al administrador" do
    failing = Object.new
    def failing.refresh! = raise(InstagramService::FetchError, "token vencido")

    original_new = InstagramService.method(:new)
    InstagramService.define_singleton_method(:new) { |*| failing }
    begin
      assert_enqueued_emails 1 do
        InstagramRefreshJob.perform_now
      end
    ensure
      InstagramService.define_singleton_method(:new, original_new)
    end
  end

  test "el aviso no se envía si no hay ADMIN_EMAIL" do
    saved = ENV.delete("ADMIN_EMAIL")
    assert_nil AdminMailer.instagram_failure("x").message.to
  ensure
    ENV["ADMIN_EMAIL"] = saved if saved
  end

  test "el aviso va a ADMIN_EMAIL con el error" do
    saved = ENV["ADMIN_EMAIL"]
    ENV["ADMIN_EMAIL"] = "admin@example.com"
    mail = AdminMailer.instagram_failure("token vencido")
    assert_equal [ "admin@example.com" ], mail.to
    assert_match "token vencido", mail.body.encoded
  ensure
    ENV["ADMIN_EMAIL"] = saved
  end
end
