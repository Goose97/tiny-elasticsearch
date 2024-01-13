# frozen_string_literal: true

require_relative '../../index/tokenizer'

describe Index::Tokenizer do
  describe '#tokenize' do
    context 'given a text payload' do
      it 'yields alphanumeric downcased tokens' do
        tokenizer = described_class.new

        tokens = []
        tokenizer.tokenize('Hello World %$^ abc@123') { |token| tokens << token }

        expect(tokens).to eq(%w[hello world abc 123])
      end

      it 'yields unique tokens' do
        tokenizer = described_class.new

        tokens = []
        tokenizer.tokenize('Hello World hello') { |token| tokens << token }

        expect(tokens).to eq(%w[hello world])
      end
    end
  end
end
