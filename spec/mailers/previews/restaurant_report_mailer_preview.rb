class RestaurantReportMailerPreview < ActionMailer::Preview
  def periodic_report
  business = Business.first
  ActsAsTenant.current_tenant = business

  user = business.users.first

    RestaurantReportMailer.periodic_report(
      user,
      business,
      Date.today - 1.year,
      Date.today,
      'weekly'
    )
  end
end
