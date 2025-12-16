class PromotionalMailer < ApplicationMailer
  default from: "Haider Ali <hello@tablr.io>"
  include AnalyticsHelper
  include Rails.application.routes.url_helpers

  def cold_email_outreach(contact, custom_body: nil, custom_subject: nil, preview: false)
    @recipient_name = contact.first_name
    @company_name = contact.company.downcase.split.map(&:titleize).join(" ")
    @recipient_email = contact.email
    @place = contact.place
    @preview = preview
    @email = contact.email

    @reviews_count = @place.reviews.where.not(sentiment: nil).count
    @positive_reviews_count = @place.reviews.where(sentiment: :positive).count
    @negative_reviews_count = @place.reviews.where(sentiment: :negative).count
    @neutral_reviews_count = @place.reviews.where(sentiment: :neutral).count
    @positive_reviews_percentage = (@positive_reviews_count.to_f / @reviews_count.to_f * 100).round(2)
    @negative_reviews_percentage = (@negative_reviews_count.to_f / @reviews_count.to_f * 100).round(2)
    @neutral_reviews_percentage = (@neutral_reviews_count.to_f / @reviews_count.to_f * 100).round(2)

    reviews = @place.reviews.where(processed: true)
                              .includes(:keywords, :complains, :suggestions)

    complaints_scope = Complain.where(review_id: reviews.select(:id))
    suggestions_scope = Suggestion.where(review_id: reviews.select(:id))
    keyword_scope = Keyword.where(review_id: reviews.select(:id))

    top_positive_keywords = top_keywords(keyword_scope.where(sentiment: :positive))
    top_negative_keywords = top_keywords(keyword_scope.where(sentiment: :negative))

    complaint_summary = build_feedback_summary(complaints_scope)
    suggestion_summary = build_feedback_summary(suggestions_scope)

    @complaint_categories = Array(complaint_summary[:categories]).first(4)
    @suggestion_categories = Array(suggestion_summary[:categories]).first(4)
    @complaint_topics = Array(complaint_summary[:top]).first(4)
    @suggestion_topics = Array(suggestion_summary[:top]).first(4)
    @positive_keywords = Array(top_positive_keywords)
    @negative_keywords = Array(top_negative_keywords)

    @positive_theme_words = @positive_keywords.first(3).map { |keyword| keyword[:name].to_s.titleize }.reject(&:blank?)
    @positive_theme_sentence =
      if @positive_theme_words.any?
        "Guests mention #{@positive_theme_words.to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')} most often"
      else
        "Guests frequently call out the warm hospitality and overall vibe."
      end

    @top_complaint = @complaint_topics.first&.dig(:text)&.to_s&.titleize

    # Use custom subject and body if provided
    subject = custom_subject || "Feedback analysis for #{contact.company.downcase.split.map(&:titleize).join(" ")}"
    @custom_body = custom_body

    mail(
      to: contact.email,
      subject: subject,
      headers: {
        'List-Unsubscribe' => "<#{unsubscribe_url(email: contact.email)}>"
      }
    ) do |format|
        format.html
    end
  end

  def hidden_patterns_in_reviews(contact)
    @recipient_name = contact.first_name
    @company_name = contact.company
    @recipient_email = contact.email

    mail(
      to: contact.email,
      subject: "Hidden patterns in #{contact.company} online reviews",
      headers: {
        'List-Unsubscribe' => "<#{unsubscribe_url(email: contact.email)}>"
      }
    )
  end

  def analyzing_reviews_pattern(contact)
    @recipient_name = contact.first_name
    @company_name = contact.company
    @recipient_email = contact.email

    mail(
      to: contact.email,
      subject: "Analyzing reviews pattern in #{contact.company} online reviews",
      headers: {
        'List-Unsubscribe' => "<#{unsubscribe_url(email: contact.email)}>"
      }
    )
  end
end
