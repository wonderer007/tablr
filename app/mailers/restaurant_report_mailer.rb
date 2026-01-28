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

  def insights_digest(user, business)
    @user = user
    @business = business
    @complaints = fetch_latest_complaints
    @suggestions = fetch_latest_suggestions

    return if @complaints.empty? && @suggestions.empty?

    @generated_at = Time.current

    headers['List-Unsubscribe'] = "<#{settings_url}>"
    headers['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click'

    mail(
      to: user.email,
      subject: "Customer Insights Available For #{@business.name}"
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

  def fetch_latest_complaints
    ActsAsTenant.with_tenant(@business) do
      Complain.includes(:category, :review)
              .order(severity: :desc)
              .limit(5)
    end
  end

  def fetch_latest_suggestions
    ActsAsTenant.with_tenant(@business) do
      Suggestion.includes(:category, :review)
                .order(severity: :desc)
                .limit(5)
    end
  end
end
