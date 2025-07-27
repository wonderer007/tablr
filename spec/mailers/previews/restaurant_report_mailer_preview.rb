class RestaurantReportMailerPreview < ActionMailer::Preview
  def periodic_report
  place = Place.first
  ActsAsTenant.current_tenant = place

  user = place.users.first

    RestaurantReportMailer.periodic_report(
      user,
      place,
      Date.today - 1.year,
      Date.today,
      'weekly'
    )
  end
end
