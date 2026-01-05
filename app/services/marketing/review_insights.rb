module Marketing
  module ReviewInsights
    DEFAULT_POSITIVE_CATEGORIES = ['Food', 'Service'].freeze
    DEFAULT_NEGATIVE_CATEGORIES = ['Price', 'Timing'].freeze

    def self.for_business(business)
      previous_tenant = ActsAsTenant.current_tenant
      ActsAsTenant.current_tenant = business

      complains = Complain.group(:category_id).count.sort_by { |category_id, count| -count }
      customer_complains = complains.any? ? Complain.where(category_id: complains.first.first).where.not("text LIKE '%=>%'").limit(20).shuffle.take(2).pluck(:text) : []

      suggestions = Suggestion.group(:category_id).count.sort_by { |category_id, count| -count }
      customer_suggestions = suggestions.any? ? Suggestion.where(category_id: suggestions.first.first).where.not("text LIKE '%=>%'").limit(20).shuffle.take(2).pluck(:text) : []

      {
        customer_suggestions: customer_suggestions,
        customer_complains: customer_complains
      }
    ensure
      ActsAsTenant.current_tenant = previous_tenant
    end
  end
end

