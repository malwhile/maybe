class Settings::FeedsController < ApplicationController
  layout "settings"

  def show
    @plain_key = flash[:rss_feed_key]
    @feed_url = alert_feed_url(format: :atom)
  end

  def create
    plain_key = User.generate_rss_key
    Current.user.update!(rss_feed_key: plain_key)
    flash[:rss_feed_key] = plain_key
    redirect_to settings_feed_path
  end

  def destroy
    Current.user.revoke_rss_feed_key!
    redirect_to settings_feed_path
  end

  def update
    threshold = params.dig(:family, :large_transaction_threshold).presence
    Current.family.update!(large_transaction_threshold: threshold)
    redirect_to settings_feed_path, notice: "Settings saved"
  end
end
