class RephraseSentences
  def initialize(sentences:)
    @sentences = sentences
  end

  def call
    return client.chat(
      parameters: {
        model: 'gpt-4o-mini',
        temperature: 0.2,
        messages: [
          { role: 'system', content: "You are a helpful assistant that rephrases sentences. You will be given opening sentences from email to restaurant owner and you will need to rephrase each sentence to make it more engaging and persuasive. Also, keep the introduction words 'I analyzed recent reviews for' as it is" },
          { role: 'user', content: sentences.join('\n') }
        ]
      }
    ).dig('choices', 0, 'message', 'content')
  end

  private

  attr_reader :sentences

  def client
    @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY'))
  end
end
