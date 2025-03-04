# frozen_string_literal: true

module Zee
  module Core
    module Array
      # @api private
      TO_SENTENCE_SCOPE = "zee.core.array.to_sentence"

      # @!method to_sentence(scope: :and)
      # Converts an array to a sentence.
      # @param scope [Symbol] the scope of the sentence. Can be `:and` or `:or`.
      # @return [String]

      refine ::Array do
        def to_sentence(scope: :and)
          I18n.t(scope, scope: TO_SENTENCE_SCOPE) =>
            {two_words_connector:, words_connector:, last_word_connector:}

          case size
          when 0
            ""
          when 1
            self[0].to_s
          when 2
            "#{self[0]}#{two_words_connector}#{self[1]}"
          else
            "#{self[0...-1].join(words_connector)}#{last_word_connector}" \
            "#{self[-1]}"
          end
        end
      end
    end
  end
end
