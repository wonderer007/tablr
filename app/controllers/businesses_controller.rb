class BusinessesController < ApplicationController
  layout 'landing'

  def report
    @business = Business.find_by(place_actor_run_id: params[:id])

    ActsAsTenant.with_tenant(@business) do
      @reviews = @business.reviews.where(processed: true)

      # Summary stats
      @total_reviews = @reviews.count
      @total_complaints = Complain.where(review_id: @reviews.select(:id)).count
      @total_suggestions = Suggestion.where(review_id: @reviews.select(:id)).count

      # Top 5 complaint categories
      @top_complaint_categories = Complain.where(review_id: @reviews.select(:id))
                                          .joins(:category)
                                          .group('categories.name')
                                          .order('count_all DESC')
                                          .limit(5)
                                          .count

      # Top 5 suggestion categories
      @top_suggestion_categories = Suggestion.where(review_id: @reviews.select(:id))
                                             .joins(:category)
                                             .group('categories.name')
                                             .order('count_all DESC')
                                             .limit(5)
                                             .count

      # Top 10 complaints, sorted by severity descending, diversified by category
      @top_complaints = top_items_by_category(
        Complain.where(review_id: @reviews.select(:id)),
        10
      ).sort_by { |item| item[:severity] }.reverse

      # Top 10 suggestions, sorted by severity descending, diversified by category
      @top_suggestions = top_items_by_category(
        Suggestion.where(review_id: @reviews.select(:id)),
        10
      ).sort_by { |item| item[:severity] }.reverse

      @report_generated_at = Time.current
    end
  end

  private

  # Selects top items distributed across categories to avoid picking all from one category
  def top_items_by_category(scope, limit)
    # Group items by category and sort each group by severity descending
    items_by_category = scope.includes(:category)
                             .order(severity: :desc)
                             .group_by(&:category_id)

    return [] if items_by_category.empty?

    result = []
    category_indices = items_by_category.transform_values { 0 }

    # Round-robin selection from each category
    while result.size < limit
      added_any = false

      items_by_category.each do |category_id, items|
        break if result.size >= limit

        index = category_indices[category_id]
        if index < items.size
          result << items[index]
          category_indices[category_id] += 1
          added_any = true
        end
      end

      break unless added_any
    end

    result.map do |item|
      {
        text: item.text,
        severity: item.severity,
        category: item.category&.name
      }
    end
  end
end

