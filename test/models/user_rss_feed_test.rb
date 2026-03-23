require "test_helper"

class UserRssFeedTest < ActiveSupport::TestCase
  def setup
    @user = users(:dylan)
  end

  test "generate_rss_key returns a 64-character hex string" do
    key = User.generate_rss_key
    assert_match /^[a-f0-9]{64}$/, key
  end

  test "generate_rss_feed_key! sets the rss_feed_key" do
    @user.generate_rss_feed_key!
    assert @user.rss_feed_key.present?
  end

  test "revoke_rss_feed_key! clears the key" do
    @user.generate_rss_feed_key!
    assert @user.rss_feed_key.present?

    @user.revoke_rss_feed_key!
    assert @user.rss_feed_key.nil?
  end

  test "authenticate_rss_feed! returns user with correct email and key" do
    @user.generate_rss_feed_key!
    key = @user.rss_feed_key

    authenticated = User.authenticate_rss_feed!(@user.email, key)
    assert_equal @user.id, authenticated.id
  end

  test "authenticate_rss_feed! returns nil with wrong key" do
    @user.generate_rss_feed_key!

    authenticated = User.authenticate_rss_feed!(@user.email, "wrongkey")
    assert_nil authenticated
  end

  test "authenticate_rss_feed! returns nil with blank key" do
    authenticated = User.authenticate_rss_feed!(@user.email, "")
    assert_nil authenticated
  end

  test "authenticate_rss_feed! returns nil with blank email" do
    @user.generate_rss_feed_key!
    key = @user.rss_feed_key

    authenticated = User.authenticate_rss_feed!("", key)
    assert_nil authenticated
  end

  test "authenticate_rss_feed! returns nil when user has no key" do
    authenticated = User.authenticate_rss_feed!(@user.email, "somekey")
    assert_nil authenticated
  end

  test "authenticate_rss_feed! is case-insensitive for email" do
    @user.generate_rss_feed_key!
    key = @user.rss_feed_key

    authenticated = User.authenticate_rss_feed!(@user.email.upcase, key)
    assert_equal @user.id, authenticated.id
  end
end
