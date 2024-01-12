# frozen_string_literal: true

module Index
  class Tokenizer
    def tokenize(text)
      text.split(/\s+/)
          .map { _1.gsub(/\W/, '').downcase }
          .filter { !_1.empty? && _1.bytesize < 256 }
    end
  end
end
