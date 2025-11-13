module AnalyticsHelper
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
