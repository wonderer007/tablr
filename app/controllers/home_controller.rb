class HomeController < ApplicationController
  layout 'dashboard'
  
  def dashboard
    @start_date = params[:start_date]&.to_date || 90.days.ago.to_date
    @end_date = params[:end_date]&.to_date || Date.current
    
    # Calculate duration in days for previous period comparison
    @duration_days = (@end_date - @start_date).to_i
    @previous_start_date = @start_date - @duration_days.days
    @previous_end_date = @start_date - 1.day
    
    # Calculate current period ratings
    @current_ratings = calculate_ratings(@start_date, @end_date)
    
    # Calculate previous period ratings for comparison
    @previous_ratings = calculate_ratings(@previous_start_date, @previous_end_date)
    
    # Calculate percentage changes for ratings
    @rating_changes = calculate_rating_changes(@current_ratings, @previous_ratings)
    
    # Calculate current period review counts
    @current_reviews = calculate_review_counts(@start_date, @end_date)
    
    # Calculate previous period review counts for comparison
    @previous_reviews = calculate_review_counts(@previous_start_date, @previous_end_date)
    
    # Calculate percentage changes for reviews
    @review_changes = calculate_review_changes(@current_reviews, @previous_reviews)
    
    # Calculate current period category sentiments
    @current_category_sentiments = calculate_category_sentiments(@start_date, @end_date)
    
    # Calculate previous period category sentiments for comparison
    @previous_category_sentiments = calculate_category_sentiments(@previous_start_date, @previous_end_date)
    
    # Calculate percentage changes for category sentiments
    @category_sentiment_changes = calculate_category_sentiment_changes(@current_category_sentiments, @previous_category_sentiments)
  end
  
  private
  
  def calculate_ratings(start_date, end_date)
    reviews = Review.joins(:place)
                   .where(published_at: start_date..end_date)
                   .where.not(food_rating: nil, service_rating: nil, atmosphere_rating: nil)
    
    return default_ratings if reviews.empty?
    
    {
      overall: reviews.average(:stars)&.round(1) || 0,
      food: reviews.average(:food_rating)&.round(1) || 0,
      service: reviews.average(:service_rating)&.round(1) || 0,
      atmosphere: reviews.average(:atmosphere_rating)&.round(1) || 0
    }
  end
  
  def calculate_review_counts(start_date, end_date)
    reviews = Review.joins(:place).where(published_at: start_date..end_date)
    
    {
      total: reviews.count,
      positive: reviews.where(sentiment: :positive).count,
      negative: reviews.where(sentiment: :negative).count,
      neutral: reviews.where(sentiment: :neutral).count
    }
  end
  
  def calculate_category_sentiments(start_date, end_date)
    # Get categories that have keywords associated with reviews in the date range
    categories_with_keywords = Category.joins(keywords: :review)
                                      .where(reviews: { published_at: start_date..end_date })
                                      .distinct
                                      .includes(:keywords)
    
    category_data = {}
    
    categories_with_keywords.each do |category|
      # Get keywords for this category within the date range
      keywords_in_period = category.keywords.joins(:review)
                                           .where(reviews: { published_at: start_date..end_date })
      
      category_data[category.id] = {
        name: category.name,
        total: keywords_in_period.count,
        positive: keywords_in_period.where(sentiment: :positive).count,
        negative: keywords_in_period.where(sentiment: :negative).count,
        neutral: keywords_in_period.where(sentiment: :neutral).count,
        positive_percentage: calculate_percentage(keywords_in_period.where(sentiment: :positive).count, keywords_in_period.count),
        negative_percentage: calculate_percentage(keywords_in_period.where(sentiment: :negative).count, keywords_in_period.count),
        neutral_percentage: calculate_percentage(keywords_in_period.where(sentiment: :neutral).count, keywords_in_period.count)
      }
    end
    
    category_data
  end
  
  def calculate_category_sentiment_changes(current, previous)
    changes = {}
    
    current.each do |category_id, current_data|
      previous_data = previous[category_id]
      changes[category_id] = {}
      
      [:total, :positive, :negative, :neutral].each do |sentiment_type|
        current_value = current_data[sentiment_type]
        previous_value = previous_data ? previous_data[sentiment_type] : 0
        
        if previous_value && previous_value > 0
          change = ((current_value - previous_value) / previous_value.to_f * 100).round(1)
          changes[category_id][sentiment_type] = {
            value: change,
            positive: change >= 0
          }
        else
          if current_value > 0
            changes[category_id][sentiment_type] = { value: 100, positive: true }
          else
            changes[category_id][sentiment_type] = { value: 0, positive: true }
          end
        end
      end
      
      # Add category name for easy access
      changes[category_id][:name] = current_data[:name]
    end
    
    changes
  end
  
  def calculate_percentage(part, total)
    return 0 if total == 0
    ((part.to_f / total) * 100).round(1)
  end
  
  def calculate_rating_changes(current, previous)
    changes = {}
    
    current.each do |key, current_value|
      previous_value = previous[key]
      
      if previous_value && previous_value > 0
        change = ((current_value - previous_value) / previous_value * 100).round(1)
        changes[key] = {
          value: change,
          positive: change >= 0
        }
      else
        changes[key] = { value: 0, positive: true }
      end
    end
    
    changes
  end
  
  def calculate_review_changes(current, previous)
    changes = {}
    
    current.each do |key, current_value|
      previous_value = previous[key]
      
      if previous_value && previous_value > 0
        change = ((current_value - previous_value) / previous_value.to_f * 100).round(1)
        changes[key] = {
          value: change,
          positive: change >= 0
        }
      else
        # If previous value is 0 but current value > 0, show as 100% increase
        if current_value > 0
          changes[key] = { value: 100, positive: true }
        else
          changes[key] = { value: 0, positive: true }
        end
      end
    end
    
    changes
  end
  
  def default_ratings
    { overall: 0, food: 0, service: 0, atmosphere: 0 }
  end
end
