# frozen_string_literal: true

module Index
  class Tokenizer
    def tokenize(text)
      text.split(/\s+/).map(&:downcase)
    end
  end
end
