# frozen_string_literal: true

require_relative '../../index/tokenizer'
require_relative '../../index/indexer'
require_relative '../../query/querier'

describe Query::Querier do
  describe '#query' do
    context 'given a single segment' do
      it 'queries all documents' do
        reset_tmp_folder
        tokenizer = Index::Tokenizer.new
        indexer = Index::Indexer.new(data_path: 'tmp/querier_test',
                                     tokenizer:,
                                     buffer_size: 5,
                                     merge_worker: false)

        indexer.add_document({ text: 'Postgres is a SQL database', title: 'Postgres' })
        indexer.add_document({ text: 'Lucene is a search database', title: 'Lucene' })
        indexer.add_document({ text: 'Postgres and Lucene are both databases', title: 'Databases' })
        indexer.flush

        result1 = described_class.new(data_path: 'tmp/querier_test').query('database').map { _1['title'] }
        result2 = described_class.new(data_path: 'tmp/querier_test').query('search').map { _1['title'] }
        result3 = described_class.new(data_path: 'tmp/querier_test').query('postgres').map { _1['title'] }

        expect(result1).to contain_exactly('Postgres', 'Lucene')
        expect(result2).to contain_exactly('Lucene')
        expect(result3).to contain_exactly('Postgres', 'Databases')

        FileUtils.rm_rf('tmp')
      end
    end

    context 'given multiple segment' do
      it 'queries all documents' do
        reset_tmp_folder
        tokenizer = Index::Tokenizer.new
        indexer = Index::Indexer.new(data_path: 'tmp/querier_test',
                                     tokenizer:,
                                     buffer_size: 1,
                                     merge_worker: false)

        indexer.add_document({ text: 'Postgres is a SQL database', title: 'Postgres' })
        indexer.add_document({ text: 'Lucene is a search database', title: 'Lucene' })
        indexer.add_document({ text: 'Postgres and Lucene are both databases', title: 'Databases' })
        indexer.flush

        result1 = described_class.new(data_path: 'tmp/querier_test').query('database').map { _1['title'] }
        result2 = described_class.new(data_path: 'tmp/querier_test').query('search').map { _1['title'] }
        result3 = described_class.new(data_path: 'tmp/querier_test').query('postgres').map { _1['title'] }

        expect(result1).to contain_exactly('Postgres', 'Lucene')
        expect(result2).to contain_exactly('Lucene')
        expect(result3).to contain_exactly('Postgres', 'Databases')

        FileUtils.rm_rf('tmp')
      end
    end
  end

  def reset_tmp_folder
    FileUtils.rm_rf('tmp')
    FileUtils.mkdir_p('tmp/querier_test')
  end
end
