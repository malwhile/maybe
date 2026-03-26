require "test_helper"

class AlertFeedsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:dylan)
    @family = @user.family
    @user.generate_rss_feed_key!
    @key = @user.rss_feed_key

    # Create a test alert
    @alert = Alert.create!(
      family: @family,
      alert_type: "budget_exceeded",
      metadata: { category_name: "Test", actual_spending: "100", budgeted_spending: "50" }
    )
  end

  test "GET /alerts.atom with valid credentials returns 200" do
    get alert_feed_url(format: :atom), headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, @key) }
    assert_response :success
    assert_equal "application/atom+xml", response.content_type
  end

  test "GET /alerts.atom with wrong key returns 401" do
    get alert_feed_url(format: :atom), headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, "wrongkey") }
    assert_response :unauthorized
  end

  test "GET /alerts.atom without credentials returns 401" do
    get alert_feed_url(format: :atom)
    assert_response :unauthorized
    assert response.headers.include?("WWW-Authenticate")
  end

  test "GET /alerts.rss redirects to .atom" do
    get "/alerts.rss", headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, @key) }
    assert_response :success
    assert_equal "application/atom+xml", response.content_type
  end

  test "feed contains the family's alerts" do
    get alert_feed_url(format: :atom), headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, @key) }
    assert_response :success
    assert_includes response.body, @alert.title
    assert_includes response.body, @alert.description
  end

  test "feed does not contain alerts from other families" do
    other_family = families(:two)
    other_alert = Alert.create!(
      family: other_family,
      alert_type: "budget_exceeded",
      metadata: { category_name: "Other" }
    )

    get alert_feed_url(format: :atom), headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, @key) }
    assert_response :success
    assert_includes response.body, @alert.title
    assert_not_includes response.body, other_alert.title
  end

  test "feed returns valid Atom XML" do
    get alert_feed_url(format: :atom), headers: { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, @key) }
    assert_response :success
    assert response.body.include?("<?xml")
    assert response.body.include?("<feed")
    assert response.body.include?("<entry")
  end
end
