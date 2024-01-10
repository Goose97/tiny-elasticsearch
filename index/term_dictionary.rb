# frozen_string_literal: true

module Index
  class TermDictionary
    def self.term_dictionary_file(data_path:)
      "#{data_path}/term_dictionary"
    end

    def initialize(data_path:, posting_list_storage:)
      @path = TermDictionary.term_dictionary_file(data_path:)

      # Map term to posting list offset
      @dictionary = {}
      @dictionary_mutex = Mutex.new

      @posting_list_storage = posting_list_storage

      init_data_file
    end

    def add_terms(terms, document_id)
      @dictionary_mutex.synchronize do
        terms.each { |term| add_term(term, document_id) }
      end
    end

    def persist
      fd = open_file_handler

      @dictionary_mutex.synchronize do
        @dictionary.each do |term, posting_list_offset|
          fd << [term.length].pack('C')
          fd << term
          fd << [posting_list_offset].pack('Q>')
        end
      end

      fd.flush
    end

    def each
      @dictionary.each do |term, posting_list_offset|
        yield [term, posting_list_offset]
      end
    end

    def get_posting_list(term)
      offset = @dictionary[term]
      return unless offset

      @posting_list_storage.get_posting_list(offset)
    end

    private

    attr_reader :path, :dictionary, :file_handler

    def init_data_file
      return load_from_data_file if File.exist?(@path)

      File.new(@path, 'w')
    end

    def load_from_data_file
      File.open(@path, 'rb') do |f|
        loop do
          byte = f.read(1)
          break unless byte

          term_length = byte.unpack1('C')
          term = f.read(term_length)
          posting_list_offset = f.read(8).unpack1('Q>')

          @dictionary[term] = posting_list_offset
        end
      end
    end

    def open_file_handler
      FileUtils.mkdir_p(File.dirname(@path))
      fd = IO.sysopen(@path, 'wb')

      IO.new(fd)
    end

    def add_term(term, document_id)
      offset = @dictionary[term]

      current_list = if offset
                       @posting_list_storage.get_posting_list(offset)
                     else
                       []
                     end

      offset = @posting_list_storage.add_posting_list(current_list << document_id)
      @dictionary[term] = offset
    end
  end
end
