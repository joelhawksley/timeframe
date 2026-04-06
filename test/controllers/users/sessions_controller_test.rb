# frozen_string_literal: true

require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Warden::Test::Helpers

  def teardown
    Warden.test_reset!
  end

  test "create sends magic link and redirects" do
    test_user
    Timeframe::Application.stub(:multi_tenant?, true) do
      ActionMailer::Base.stub(:delivery_method, :test) do
        post "/users/sign_in", params: {user: {email: "newuser@example.com"}}
        assert_response :redirect
        user = User.find_by(email: "newuser@example.com")
        assert user
        assert user.magic_link_nonce.present?
      end
    end
  end

  test "create redirects to root when already signed in" do
    login_as(test_user, scope: :user)
    post "/users/sign_in", params: {user: {email: "ignored@example.com"}}
    assert_response :redirect
    assert_equal "/", response.location.sub(%r{https?://[^/]+}, "")
  end

  test "new redirects to root when already signed in" do
    login_as(test_user, scope: :user)
    Timeframe::Application.stub(:multi_tenant?, true) do
      get "/users/sign_in"
      assert_response :redirect
    end
  end
end
