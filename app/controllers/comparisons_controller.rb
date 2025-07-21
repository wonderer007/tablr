class ComparisonsController < ApplicationController
  layout 'dashboard'

  def index
    respond_to do |format|
      format.html do
        # Render the comparisons page
      end
      format.json do
        # Handle full date format (YYYY-MM-DD) from date range picker
        begin
          if params[:start_date].present?
            # Try parsing as full date first, then fall back to month format
            start_date = params[:start_date].match?(/^\d{4}-\d{2}-\d{2}$/) ? 
                          Date.parse(params[:start_date]) : 
                          Date.strptime(params[:start_date], '%Y-%m').beginning_of_month
          else
            start_date = 12.months.ago.to_date.beginning_of_month
          end
        rescue ArgumentError, TypeError
          start_date = 12.months.ago.to_date.beginning_of_month
        end
        
        begin
          if params[:end_date].present?
            # Try parsing as full date first, then fall back to month format
            end_date = params[:end_date].match?(/^\d{4}-\d{2}-\d{2}$/) ? 
                        Date.parse(params[:end_date]) : 
                        Date.strptime(params[:end_date], '%Y-%m').end_of_month
          else
            end_date = Date.current.end_of_month
          end
        rescue ArgumentError, TypeError
          end_date = Date.current.end_of_month
        end

        # Gather reviews for the range
        reviews = Review.where(published_at: start_date..end_date).sort_by(&:published_at)
        reviews_by_month = reviews.group_by { |r| Date.new(r.published_at.year, r.published_at.month, 1) }

        months = (start_date.beginning_of_month..end_date.end_of_month).map { |d| Date.new(d.year, d.month, 1) }.uniq
        ratings_by_month = months.map do |month|
          month_reviews = reviews_by_month[month] || []
          stars = month_reviews.map(&:stars).compact
          food = month_reviews.map(&:food_rating).compact
          service = month_reviews.map(&:service_rating).compact
          atmosphere = month_reviews.map(&:atmosphere_rating).compact
          {
            month: month.strftime('%Y-%m'),
            average_rating: stars.presence ? (stars.sum.to_f / stars.size).round(2) : 0,
            food_rating: food.presence ? (food.sum.to_f / food.size).round(2) : 0,
            service_rating: service.presence ? (service.sum.to_f / service.size).round(2) : 0,
            atmosphere_rating: atmosphere.presence ? (atmosphere.sum.to_f / atmosphere.size).round(2) : 0
          }
        end

        render json: ratings_by_month
      end
    end
  end
end 