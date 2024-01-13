# frozen_string_literal: true

require_relative '../../index/tokenizer'
require_relative '../../index/indexer'
require_relative '../../index/term_dictionary'

describe Index::Indexer do
  describe '#add_document' do
    context 'given a document' do
      it 'indexes the document' do
        reset_tmp_folder
        tokenizer = Index::Tokenizer.new
        indexer = Index::Indexer.new(data_path: 'tmp/indexer_test', tokenizer:, buffer_size: 3)

        indexer.add_document({ text: 'Postgres is a SQL database', title: 'Postgres' })
        indexer.add_document({ text: 'Lucene is a search database', title: 'Lucene' })
        indexer.add_document({ text: 'Postgres and Lucene are both databases', title: 'Databases' })

        posting_list_storage = Index::PostingListStorage.new(data_path: 'tmp/indexer_test/segment_0')
        term_dictionary = Index::TermDictionary.new(data_path: 'tmp/indexer_test/segment_0',
                                                    posting_list_storage:)

        expect(term_dictionary.get_posting_list('postgres')).to contain_exactly(0, 2)
        expect(term_dictionary.get_posting_list('and')).to contain_exactly(2)
        expect(term_dictionary.get_posting_list('database')).to contain_exactly(0, 1)
        expect(term_dictionary.get_posting_list('databases')).to contain_exactly(2)
        expect(term_dictionary.get_posting_list('search')).to contain_exactly(1)
        expect(term_dictionary.get_posting_list('lucene')).to contain_exactly(1, 2)

        indexer.shutdown
        FileUtils.rm_rf('tmp')
      end
    end
  end

  def reset_tmp_folder
    FileUtils.rm_rf('tmp')
    FileUtils.mkdir_p('tmp/indexer_test')
  end
end
