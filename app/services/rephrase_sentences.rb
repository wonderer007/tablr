class RephraseSentences
  def initialize(sentences:)
    @sentences = sentences
  end

  def call
    return client.chat(
      parameters: {
        model: 'gpt-4o-mini',
        temperature: 0.2,
        messages: prompt
      }
    ).dig('choices', 0, 'message', 'content')
  end

  private

  attr_reader :sentences

  def prompt
    [
      { role: 'system', content: system_prompt },
      { role: 'user', content: user_prompt }
    ]
  end

  def system_prompt
    <<~PROMPT
      You are a helpful assistant with expertise in marketing and copywriting.
      You will be given opening sentences from email to business owners and you will need to rephrase each sentence to make it more engaging and persuasive.
      Particularly, if the sentence is about customer feedback, you should rephrase it to make it more actionable and persuasive.
      Add html tags to the sentences for better readability.
      Keep introduction short and concise, don't add any extra information.
      Do NOT use <bold>, <strong>, <b>, <italic>, <i>, or <em> tags. Keep formatting clean and professional.
      Use customer-centric and personalized language such as:
      - "I analyzed your reviews and found..."
      - "Your customers are complaining about..."
      - "Your customers are suggesting..."
      - "Your customers want..."
      Make the tone feel like a personal insight based on real customer feedback analysis.
    PROMPT
  end

  def user_prompt
    sentences.join("\n")
  end

  def client
    @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end
end
