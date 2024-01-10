# frozen_string_literal: true

require_relative '../../index/term_dictionary'
require_relative '../../index/posting_list_storage'

describe Index::PostingListStorage do
  describe '#add_posting_list' do
    context 'given a posting list' do
      it 'stores the posting list and returns the offset' do
        reset_tmp_folder
        posting_list_storage = described_class.new(data_path: 'tmp/posting_list_storage_test')

        offset0 = posting_list_storage.add_posting_list([0, 1, 2, 3, 4])
        offset1 = posting_list_storage.add_posting_list([5, 6])

        expect(offset0).to be_a(Integer)
        expect(offset1).to be_a(Integer)

        FileUtils.rm_rf('tmp')
      end
    end
  end

  describe '#get_posting_list' do
    context 'given a valid offset' do
      it 'returns the posting list' do
        reset_tmp_folder
        posting_list_storage = described_class.new(data_path: 'tmp/posting_list_storage_test')

        offset0 = posting_list_storage.add_posting_list([0, 1, 2, 3, 4])
        offset1 = posting_list_storage.add_posting_list([5, 6])

        expect(posting_list_storage.get_posting_list(offset0)).to eq([0, 1, 2, 3, 4])
        expect(posting_list_storage.get_posting_list(offset1)).to eq([5, 6])

        FileUtils.rm_rf('tmp')
      end
    end

    context 'given an out of bound offset' do
      it 'raises an error' do
        reset_tmp_folder
        posting_list_storage = described_class.new(data_path: 'tmp/posting_list_storage_test')

        posting_list_storage.add_posting_list([0, 1, 2, 3, 4])

        expect do
          posting_list_storage.get_posting_list(1024)
        end.to raise_error(RuntimeError, 'Invalid offset')

        FileUtils.rm_rf('tmp')
      end
    end
  end

  def reset_tmp_folder
    FileUtils.rm_rf('tmp')
    FileUtils.mkdir_p('tmp/posting_list_storage_test')
  end
end
