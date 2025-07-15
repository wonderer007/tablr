class SuggestionsController < ApplicationController
  layout 'dashboard'

  def index
    @q = Suggestion.includes(:category, review: :place).ransack(params[:q])
    @suggestions = @q.result
    
    # Only apply default ordering if no search or sort parameters are present
    if params[:q].blank? || (params[:q][:s].blank? && params[:q][:text_cont].blank? && params[:q][:category_id_eq].blank? && params[:q][:review_published_at_gteq].blank? && params[:q][:review_published_at_lteq].blank?)
      @suggestions = @suggestions.joins(:review).order('reviews.published_at DESC')
    end
    @suggestions = @suggestions.page(params[:page]).per(30)
  end
end
