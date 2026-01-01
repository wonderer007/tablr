class RestaurantReportMailer < ApplicationMailer
  def periodic_report(user, business, start_date, end_date, report_type = 'weekly')
    @user = user
    @business = business
    @start_date = start_date
    @end_date = end_date
    @report_type = report_type
    
    @report_data = generate_report_data

    mail(
      to: user.email,
      subject: "#{@business.name} - #{@report_type.titleize} Performance Report (#{@start_date.strftime('%b %d %Y')} - #{@end_date.strftime('%b %d, %Y')})"
    )
  end

  private

  def generate_report_data
    ReviewAnalyticsService.new(
      business: @business,
      start_date: @start_date,
      end_date: @end_date
    ).call
  end
end
