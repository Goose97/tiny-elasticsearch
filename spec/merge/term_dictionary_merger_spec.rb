# frozen_string_literal: true

require_relative '../../merge/term_dictionary_merger'
require_relative '../../index/document_storage'
require_relative '../../index/term_dictionary'
require_relative '../../index/posting_list_storage'
require 'fileutils'

describe Merge::SegmentMerger::TermDictionaryMerger do
  context 'given two segments' do
    it 'merges their term dictionaries and keep the sorted order' do
      reset_tmp_folder

      posting_list_a = Index::PostingListStorage.new(data_path: 'tmp/merge_test/segment_a')
      term_dictionary_a = Index::TermDictionary.new(data_path: 'tmp/merge_test/segment_a',
                                                    posting_list_storage: posting_list_a)
      posting_list_b = Index::PostingListStorage.new(data_path: 'tmp/merge_test/segment_b')
      term_dictionary_b = Index::TermDictionary.new(data_path: 'tmp/merge_test/segment_b',
                                                    posting_list_storage: posting_list_b)

      term_dictionary_a.add_terms(['this', 'is', 'a', 'test', 'a.0'], 0)
      term_dictionary_a.add_terms(['this', 'is', 'a', 'test', 'a.1'], 1)
      term_dictionary_b.add_terms(['that', 'was', 'another', 'test', 'b.2'], 2)
      term_dictionary_b.add_terms(['this', 'is', 'not', 'a', 'test', 'b.3'], 3)

      term_dictionary_a.persist
      term_dictionary_b.persist

      merger = described_class.new(data_path: 'tmp/merge_test',
                                   segment_a: 'a',
                                   segment_b: 'b',
                                   new_segment: 'c')
      merger.call

      expect(all_terms('tmp/merge_test/segment_c')).to eq(['a', 'a.0', 'a.1', 'another', 'b.2',
                                                           'b.3', 'is', 'not',
                                                           'test', 'that', 'this', 'was'])

      FileUtils.rm_rf('tmp')
    end

    it 'merges their posting list' do
      reset_tmp_folder

      posting_list_a = Index::PostingListStorage.new(data_path: 'tmp/merge_test/segment_a')
      term_dictionary_a = Index::TermDictionary.new(data_path: 'tmp/merge_test/segment_a',
                                                    posting_list_storage: posting_list_a)
      posting_list_b = Index::PostingListStorage.new(data_path: 'tmp/merge_test/segment_b')
      term_dictionary_b = Index::TermDictionary.new(data_path: 'tmp/merge_test/segment_b',
                                                    posting_list_storage: posting_list_b)

      term_dictionary_a.add_terms(['this', 'is', 'a', 'test', 'a.0'], 0)
      term_dictionary_a.add_terms(['this', 'is', 'a', 'test', 'a.1'], 1)
      term_dictionary_b.add_terms(['that', 'was', 'another', 'test', 'b.2'], 2)
      term_dictionary_b.add_terms(['this', 'is', 'not', 'a', 'test', 'b.3'], 3)

      term_dictionary_a.persist
      term_dictionary_b.persist

      merger = described_class.new(data_path: 'tmp/merge_test',
                                   segment_a: 'a',
                                   segment_b: 'b',
                                   new_segment: 'c')
      merger.call

      merged_posting_list = Index::PostingListStorage.new(data_path: 'tmp/merge_test/segment_c')
      merged_dictionary = Index::TermDictionary.new(data_path: 'tmp/merge_test/segment_c',
                                                    posting_list_storage: merged_posting_list)

      expect(merged_dictionary.get_posting_list('this')).to contain_exactly(0, 1, 3)
      expect(merged_dictionary.get_posting_list('that')).to contain_exactly(2)
      expect(merged_dictionary.get_posting_list('was')).to contain_exactly(2)
      expect(merged_dictionary.get_posting_list('is')).to contain_exactly(0, 1, 3)
      expect(merged_dictionary.get_posting_list('test')).to contain_exactly(0, 1, 2, 3)
      expect(merged_dictionary.get_posting_list('a.1')).to contain_exactly(1)
      expect(merged_dictionary.get_posting_list('b.3')).to contain_exactly(3)

      FileUtils.rm_rf('tmp')
    end
  end

  def all_terms(segment_path)
    dictionary = Index::TermDictionary.new(data_path: segment_path, posting_list_storage: nil)

    terms = []

    # rubocop:disable Style/HashEachMethods
    dictionary.each do |term, _|
      terms << term
    end
    # rubocop:enable Style/HashEachMethods

    terms
  end

  def reset_tmp_folder
    FileUtils.rm_rf('tmp')
    FileUtils.mkdir_p('tmp/merge_test')
  end
end
