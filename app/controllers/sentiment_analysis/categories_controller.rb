class SentimentAnalysis::CategoriesController < ApplicationController
  layout 'dashboard'

  def index
    # Initialize Ransack search object
    @q = Keyword.joins(:review).ransack(params[:q])
    
    # Build base query for keywords with date filtering
    keywords_scope = @q.result
    
    # Get category stats using the filtered keywords
    @categories_with_stats = Category.joins(:keywords)
      .joins('INNER JOIN reviews ON keywords.review_id = reviews.id')
      .where(keywords: { id: keywords_scope.select(:id) })
      .select('categories.*, 
               COUNT(keywords.id) as total_keywords,
               COUNT(CASE WHEN keywords.sentiment = 0 THEN 1 END) as positive_count,
               COUNT(CASE WHEN keywords.sentiment = 1 THEN 1 END) as negative_count,
               COUNT(CASE WHEN keywords.sentiment = 2 THEN 1 END) as neutral_count,
               CASE 
                 WHEN COUNT(keywords.id) > 0 
                 THEN ROUND((COUNT(CASE WHEN keywords.sentiment = 0 THEN 1 END) * 100.0 / COUNT(keywords.id)), 1)
                 ELSE 0 
               END as positive_percentage,
               AVG(keywords.sentiment_score) as avg_sentiment_score')
      .group('categories.id')
      .having('COUNT(keywords.id) > 0')
      .order('total_keywords DESC, categories.name ASC')
    
    # Calculate overall statistics with date filtering
    @total_keywords = keywords_scope.count
    @overall_positive = keywords_scope.where(sentiment: :positive).count
    @overall_negative = keywords_scope.where(sentiment: :negative).count  
    @overall_neutral = keywords_scope.where(sentiment: :neutral).count
  end

  def show
    @category = Category.find(params[:id])
    
    # Set up Ransack search for keywords in this category
    @q = @category.keywords.includes(:review).ransack(params[:q])
    @keywords = @q.result.page(params[:page]).per(20)
    
    # Category statistics
    @total_keywords = @category.keywords.count
    @positive_count = @category.keywords.where(sentiment: :positive).count
    @negative_count = @category.keywords.where(sentiment: :negative).count
    @neutral_count = @category.keywords.where(sentiment: :neutral).count
    @avg_sentiment_score = @category.keywords.average(:sentiment_score)&.round(2) || 0
  end
end
