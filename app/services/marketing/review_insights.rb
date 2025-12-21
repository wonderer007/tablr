module Marketing
  module ReviewInsights
    DEFAULT_POSITIVE_CATEGORIES = ['Food', 'Service'].freeze
    DEFAULT_NEGATIVE_CATEGORIES = ['Price', 'Timing'].freeze

    def self.for_place(place)
      previous_tenant = ActsAsTenant.current_tenant
      ActsAsTenant.current_tenant = place

      positive_counts = Hash.new(0)
      negative_counts = Hash.new(0)

      Keyword.positive.each { |keyword| positive_counts[keyword.category_id] += 1 }
      Keyword.negative.each { |keyword| negative_counts[keyword.category_id] += 1 }

      sorted_positive_ids = positive_counts.sort_by { |category_id, count| -count }.map(&:first)
      sorted_negative_ids = negative_counts.sort_by { |category_id, count| -count }.map(&:first)

      positive_categories =
        if sorted_positive_ids.any?
          Category.where(id: sorted_positive_ids).pluck(:name)
        else
          DEFAULT_POSITIVE_CATEGORIES
        end

      negative_categories =
        if sorted_negative_ids.any?
          Category.where(id: sorted_negative_ids).pluck(:name)
        else
          DEFAULT_NEGATIVE_CATEGORIES
        end

      complains = Complain.group(:category_id).count.sort_by { |category_id, count| -count }
      customer_complains = complains.any? ? Complain.where(category_id: complains.first.first).limit(2).pluck(:text) : []

      suggestions = Suggestion.group(:category_id).count.sort_by { |category_id, count| -count }
      customer_suggestions = suggestions.any? ? Suggestion.where(category_id: suggestions.first.first).limit(2).pluck(:text) : []

      feedback = [customer_suggestions.sample(2), customer_complains.sample(2), negative_categories.first(2)].flatten.compact.uniq

      {
        positive_categories: positive_categories,
        negative_categories: negative_categories,
        feedback: feedback
      }
    ensure
      ActsAsTenant.current_tenant = previous_tenant
    end
  end
end

