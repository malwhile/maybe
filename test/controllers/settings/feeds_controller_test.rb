require "test_helper"

class Settings::FeedsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:dylan)
    sign_in(@user)
  end

  test "GET /settings/feed renders correctly" do
    get settings_feed_path
    assert_response :success
    assert_includes response.body, "Alert Feed"
  end

  test "POST /settings/feed generates a key" do
    assert_nil @user.rss_feed_key
    post settings_feed_path
    assert_response :redirect

    @user.reload
    assert @user.rss_feed_key.present?
  end

  test "POST /settings/feed sets flash with the key" do
    post settings_feed_path
    assert_redirected_to settings_feed_path
    assert flash[:rss_feed_key].present?
  end

  test "DELETE /settings/feed revokes the key" do
    @user.generate_rss_feed_key!
    assert @user.rss_feed_key.present?

    delete settings_feed_path
    assert_response :redirect

    @user.reload
    assert @user.rss_feed_key.nil?
  end

  test "PATCH /settings/feed updates large_transaction_threshold" do
    patch settings_feed_path, params: {
      family: { large_transaction_threshold: "500.00" }
    }
    assert_response :redirect

    @user.family.reload
    assert_equal 500.0, @user.family.large_transaction_threshold
  end

  test "PATCH /settings/feed clears large_transaction_threshold when blank" do
    @user.family.update!(large_transaction_threshold: 100)

    patch settings_feed_path, params: {
      family: { large_transaction_threshold: "" }
    }
    assert_response :redirect

    @user.family.reload
    assert @user.family.large_transaction_threshold.nil?
  end

  test "requires authentication" do
    sign_out
    get settings_feed_path
    assert_redirected_to new_session_path
  end
end
