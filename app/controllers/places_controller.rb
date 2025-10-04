class PlacesController < ApplicationController
  layout 'landing'

  def report
    @place = Place.find(params[:id])

    redirect_to root_path unless @place.test? 

    ActsAsTenant.with_tenant(@place) do
      @reviews = @place.reviews.where(processed: true)
                               .includes(:keywords, :complains, :suggestions)

      @total_reviews = @reviews.count
      @average_rating = (@reviews.average(:stars)&.round(1) || 0.0)

      sentiment_counts = @reviews.group(:sentiment).count
      @sentiment_stats = build_sentiment_stats(sentiment_counts)

      @rating_breakdown = {
        overall: @average_rating,
        food: average_of(@reviews, :food_rating),
        service: average_of(@reviews, :service_rating),
        atmosphere: average_of(@reviews, :atmosphere_rating)
      }

      star_counts = @reviews.group(:stars).count
      @star_distribution = (1..5).map do |stars|
        { stars:, count: star_counts[stars] || 0 }
      end.reverse

      complaints_scope = Complain.where(review_id: @reviews.select(:id))
      suggestions_scope = Suggestion.where(review_id: @reviews.select(:id))
      keyword_scope = Keyword.where(review_id: @reviews.select(:id))

      @complaint_summary = build_feedback_summary(complaints_scope)
      @suggestion_summary = build_feedback_summary(suggestions_scope)
      @opportunity_count = @complaint_summary[:total] + @suggestion_summary[:total]

      @top_positive_keywords = top_keywords(keyword_scope.where(sentiment: :positive))
      @top_negative_keywords = top_keywords(keyword_scope.where(sentiment: :negative))
      @top_dishes = top_keywords(keyword_scope.where(is_dish: true, sentiment: :positive), 4)
      @keywords_by_category = keywords_by_category(keyword_scope)
      @report_generated_at = Time.current
    end
  end

  private

  def build_sentiment_stats(counts)
    total = counts.values.sum
    stats = {
      total: total,
      positive: 0,
      negative: 0,
      neutral: 0,
      positive_percentage: 0.0,
      negative_percentage: 0.0,
      neutral_percentage: 0.0
    }

    Review.sentiments.each do |name, value|
      count = counts[name] || 0
      stats[name.to_sym] = count
      stats[:"#{name}_percentage"] = total.positive? ? ((count.to_f / total) * 100).round(1) : 0.0
    end

    stats
  end

  def build_feedback_summary(scope, limit = 5)
    return { total: 0, top: [], categories: {} } if scope.blank?

    top_items = scope.group(:text)
                     .order(Arel.sql('count_all DESC'))
                     .limit(limit)
                     .count
                     .map { |text, count| { text:, count: } }

    categories = scope.joins(:category)
                      .group('categories.name')
                      .order(Arel.sql('count_all DESC'))
                      .limit(limit)
                      .count

    {
      total: scope.count,
      top: top_items,
      categories: categories
    }
  end

  def top_keywords(scope, limit = 6)
    return [] if scope.blank?

    scope.group(:name)
         .order(Arel.sql('count_all DESC'))
         .limit(limit)
         .count
         .map { |name, count| { name:, count: } }
  end

  def keywords_by_category(keyword_scope)
    Category.includes(:keywords).map do |category|
      category_keywords = keyword_scope.where(category_id: category.id)
      total = category_keywords.count
      next if total.zero?

      {
        name: category.name,
        total: total,
        positives: top_keywords(category_keywords.where(sentiment: :positive), 3),
        negatives: top_keywords(category_keywords.where(sentiment: :negative), 3)
      }
    end.compact.sort_by { |entry| -entry[:total] }.first(4)
  end

  def average_of(scope, column)
    scope.where.not(column => nil).average(column)&.round(1) || 0.0
  end
end
