# frozen_string_literal: true

require_relative '../../merge/document_storage_merger'
require_relative '../../index/document_storage'
require_relative '../../index/term_dictionary'
require_relative '../../index/posting_list_storage'
require 'fileutils'

describe Merge::SegmentMerger::DocumentStorageMerger do
  context 'given two segments' do
    it 'merges their document files into a new segment' do
      reset_tmp_folder

      document_storage_a = Index::DocumentStorage.new(data_path: 'tmp/merge_test/segment_a')
      document_storage_b = Index::DocumentStorage.new(data_path: 'tmp/merge_test/segment_b')

      document_storage_a.add_document({ title: 'A.0' }, 0)
      document_storage_b.add_document({ title: 'B.1' }, 1)

      merger = described_class.new(data_path: 'tmp/merge_test',
                                   segment_a: 'a',
                                   segment_b: 'b',
                                   new_segment: 'c')
      merger.call

      document_storage_c = Index::DocumentStorage.new(data_path: 'tmp/merge_test/segment_c')
      document0 = document_storage_c.get_document(0)
      document1 = document_storage_c.get_document(1)

      expect(document0).to eq({ 'title' => 'A.0' })
      expect(document1).to eq({ 'title' => 'B.1' })

      FileUtils.rm_rf('tmp')
    end

    it 'maintains the sorted order of documents' do
      reset_tmp_folder

      document_storage_a = Index::DocumentStorage.new(data_path: 'tmp/merge_test/segment_a')
      document_storage_b = Index::DocumentStorage.new(data_path: 'tmp/merge_test/segment_b')

      document_storage_a.add_document({ title: 'One' }, 1)
      document_storage_b.add_document({ title: 'Two' }, 2)
      document_storage_a.add_document({ title: 'Three' }, 3)
      document_storage_a.add_document({ title: 'Four' }, 4)
      document_storage_b.add_document({ title: 'Five' }, 5)
      document_storage_b.add_document({ title: 'Six' }, 6)
      document_storage_b.add_document({ title: 'Seven' }, 7)
      document_storage_a.add_document({ title: 'Eight' }, 8)

      merger = described_class.new(data_path: 'tmp/merge_test',
                                   segment_a: 'a',
                                   segment_b: 'b',
                                   new_segment: 'c')
      merger.call

      merged_documents = all_segment_documents('tmp/merge_test/segment_c')

      expect(merged_documents.map(&:first)).to eq([1, 2, 3, 4, 5, 6, 7, 8])

      FileUtils.rm_rf('tmp')
    end
  end

  def all_segment_documents(segment_path)
    itertator_c = Index::DocumentStorage.new(data_path: segment_path).into_iterator

    documents = []

    while (document = itertator_c.next)
      documents << document
    end

    documents
  end

  def all_terms(segment_path)
    dictionary = Index::TermDictionary.new(data_path: segment_path, posting_list_storage: nil)

    terms = []

    dictionary.each do |term, _|
      terms << term
    end

    terms
  end

  def reset_tmp_folder
    FileUtils.rm_rf('tmp')
    FileUtils.mkdir_p('tmp/merge_test')
  end
end
