class RestaurantReportMailer < ApplicationMailer
  def periodic_report(user, place, start_date, end_date, report_type = 'weekly')
    @user = user
    @place = place
    @start_date = start_date
    @end_date = end_date
    @report_type = report_type
    
    @report_data = generate_report_data

    mail(
      to: user.email,
      subject: "#{@place.name} - #{@report_type.titleize} Performance Report (#{@start_date.strftime('%b %d %Y')} - #{@end_date.strftime('%b %d, %Y')})"
    )
  end

  private

  def generate_report_data
    ReviewAnalyticsService.new(
      place: @place,
      start_date: @start_date,
      end_date: @end_date
    ).call
  end
end
