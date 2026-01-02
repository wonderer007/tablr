class InsightsDigestPreview < ActionMailer::Preview
  def insights_digest
    RestaurantReportMailer.insights_digest(user, business)
  end

  private

  def user
    @user ||= business.users.order("RANDOM()").first
  end

  def business
    @business ||= Business.order("RANDOM()").first
  end
end