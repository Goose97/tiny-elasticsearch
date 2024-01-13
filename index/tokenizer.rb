# frozen_string_literal: true

module Index
  class Tokenizer
    def tokenize(text)
      tokens = Set.new

      text.scan(/\w{1,255}/).each do |word|
        token = word.downcase
        next if tokens.include?(token)

        tokens << token
        yield token
      end
    end
  end
end
