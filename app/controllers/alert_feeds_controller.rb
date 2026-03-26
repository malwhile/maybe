class AlertFeedsController < ActionController::Base
  before_action :authenticate_feed_user!

  def show
    @alerts = Current.family.alerts.recent
    respond_to do |format|
      format.atom { render layout: false }
    end
  end

  private

    def authenticate_feed_user!
      authenticate_with_http_basic do |email, key|
        user = User.authenticate_rss_feed!(email, key)
        if user
          Current.session = OpenStruct.new(user: user)
          true
        end
      end || request_http_basic_authentication("Maybe Finance Alerts")
    end
end
