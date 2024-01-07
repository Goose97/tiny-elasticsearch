# frozen_string_literal: true

module Index
  class TermDictionary
    def initialize(data_path:)
      @path = "#{data_path}/term_dictionary"
      @dictionary = {}
      @dictionary_mutex = Mutex.new

      init_data_file
    end

    def add_terms(terms, document_id)
      @dictionary_mutex.synchronize do
        terms.each do |term|
          @dictionary[term] ||= []
          @dictionary[term] << document_id
        end
      end
    end

    def persist
      fd = open_file_handler

      @dictionary_mutex.synchronize do
        @dictionary.each do |term, posting_list|
          fd << term
          fd << ' '
          fd << posting_list.pack('Q>')
          fd << "\n"
        end
      end

      fd.flush
    end

    private

    attr_reader :path, :dictionary, :file_handler

    def init_data_file
      return load_from_data_file if File.exist?(@path)

      File.new(@path, 'w')
    end

    def load_from_data_file
      File.open(@path, 'r') do |f|
        f.each_line do |line|
          term, posting_list = line.split(' ')
          posting_list = posting_list.unpack('Q>*')

          @dictionary[term] = posting_list
        end
      end
    end

    def open_file_handler
      fd = IO.sysopen(@path, 'wb')

      IO.new(fd)
    end
  end
end
