# frozen_string_literal: true

require_relative '../../index/term_dictionary'
require_relative '../../index/posting_list_storage'

describe Index::TermDictionary do
  describe '#add_terms' do
    context 'given a list of terms and a document_id' do
      it 'adds the terms in-memory' do
        reset_tmp_folder
        posting_list_storage = Index::PostingListStorage.new(data_path: 'tmp/term_dictionary_test')
        term_dictionary = described_class.new(data_path: 'tmp/term_dictionary_test',
                                              posting_list_storage:)

        term_dictionary.add_terms(%w[this is a test], 0)
        term_dictionary.add_terms(%w[and this is not a test], 1)

        terms = []

        # rubocop:disable Style/HashEachMethods
        term_dictionary.each do |term, _|
          terms << term
        end
        # rubocop:enable Style/HashEachMethods

        expect(terms).to contain_exactly('this', 'is', 'a', 'test', 'not', 'and')

        FileUtils.rm_rf('tmp')
      end
    end
  end

  describe '#persist' do
    context 'given a term dictionary' do
      it 'persists the dictionary to disk' do
        reset_tmp_folder
        posting_list_storage = Index::PostingListStorage.new(data_path: 'tmp/term_dictionary_test')
        term_dictionary = described_class.new(data_path: 'tmp/term_dictionary_test',
                                              posting_list_storage:)

        term_dictionary.add_terms(%w[this is a test], 0)
        term_dictionary.add_terms(%w[and this is not a test], 1)
        term_dictionary.persist

        # Load the dictionary from disk
        new_term_dictionary = described_class.new(data_path: 'tmp/term_dictionary_test',
                                                  posting_list_storage:)
        terms = []

        # rubocop:disable Style/HashEachMethods
        new_term_dictionary.each do |term, _|
          terms << term
        end
        # rubocop:enable Style/HashEachMethods

        expect(terms).to contain_exactly('this', 'is', 'a', 'test', 'not', 'and')

        FileUtils.rm_rf('tmp')
      end

      it 'keeps the terms sorted alphabetically' do
        reset_tmp_folder
        posting_list_storage = Index::PostingListStorage.new(data_path: 'tmp/term_dictionary_test')
        term_dictionary = described_class.new(data_path: 'tmp/term_dictionary_test',
                                              posting_list_storage:)

        term_dictionary.add_terms(%w[f h w], 0)
        term_dictionary.add_terms(%w[b a m], 1)
        term_dictionary.persist

        # Load the dictionary from disk
        new_term_dictionary = described_class.new(data_path: 'tmp/term_dictionary_test',
                                                  posting_list_storage:)
        terms = []

        # rubocop:disable Style/HashEachMethods
        new_term_dictionary.each do |term, _|
          terms << term
        end
        # rubocop:enable Style/HashEachMethods

        expect(terms).to eq(%w[a b f h m w])

        FileUtils.rm_rf('tmp')
      end
    end
  end

  describe '#get_posting_list' do
    context 'given a term' do
      it 'returns the posting list for a given term' do
        reset_tmp_folder
        posting_list_storage = Index::PostingListStorage.new(data_path: 'tmp/term_dictionary_test')
        term_dictionary = described_class.new(data_path: 'tmp/term_dictionary_test',
                                              posting_list_storage:)

        term_dictionary.add_terms(%w[this is a test], 0)
        term_dictionary.add_terms(%w[that was a test], 1)

        expect(term_dictionary.get_posting_list('this')).to eq([0])
        expect(term_dictionary.get_posting_list('is')).to eq([0])
        expect(term_dictionary.get_posting_list('a')).to eq([0, 1])
        expect(term_dictionary.get_posting_list('test')).to eq([0, 1])
        expect(term_dictionary.get_posting_list('that')).to eq([1])
        expect(term_dictionary.get_posting_list('was')).to eq([1])

        FileUtils.rm_rf('tmp')
      end
    end
  end

  def reset_tmp_folder
    FileUtils.rm_rf('tmp')
    FileUtils.mkdir_p('tmp/term_dictionary_test')
  end
end
