# frozen_string_literal: true

require 'nokogiri'
require 'fileutils'
require_relative 'wiki_parser_page'

# Copy from https://github.com/JonathanRaiman/wikipedia_parser

# Parses a Wikipedia dump and extracts internal links, content, and page type.
class WikiParser
  LANGUAGE_NODE_PROPERTY_NAME = 'xml:lang'

  # path to the Wikipedia dump.
  attr_reader :path
  # Language of the dump (e.g: "en","fr","ru",etc..)
  attr_reader :language

  # Convert the opened path to a dump to an enumerator of {WikiParser::Page}
  # @return [Enumerator<Nokogiri::XML::Node>] the enumerator.
  def prepare_enumerator
    @xml_file = File.open(@path)
    @file = Nokogiri::XML::Reader(@xml_file, nil, 'utf-8', Nokogiri::XML::ParseOptions::NOERROR)
    @reader = @file.to_enum
  end

  # Convert the opened path to a dump to an enumerator of {WikiParser::Page}
  # @param opts [Hash] the parameters to parse a wikipedia page.
  # @option opts [String] :path The path to the Wikipedia dump in .xml or .bz2 format.
  # @return [Enumerator<Nokogiri::XML::Node>] the enumerator.
  def initialize(opts = {})
    @file = nil
    new_path = opts[:path]
    unless File.exist?(new_path) && !File.directory?(new_path)
      raise ArgumentError, 'Cannot open file. Check path please.'
    end

    @path = new_path
    prepare_enumerator
    get_language
  end

  # Closes the file reader.
  def close = @xml_file.close if @xml_file

  # Skips a {WikiParser::Page} in the enumeration
  def skip
    node = @reader.next
    skip unless node.name == 'page' && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
  rescue StopIteration
    nil
  end

  # Obtains the language by reading the 'xml:lang' property in the xml of the dump.
  # @return [String] the language of the dump.
  def get_language
    node = @reader.next
    if node.name == 'mediawiki' && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
      @language = node.attribute(LANGUAGE_NODE_PROPERTY_NAME)
    else
      get_language
    end
  rescue StopIteration, NoMethodError
    nil
  end

  # Reads the next node in the xml tree and returns it as a {WikiParser#::Page} if it exists.
  # @return [WikiParser::Page, NilClass] A page if found.
  # @param opts [Hash] the parameters to instantiate a page.
  # @option opts [String] :until A node-name stopping point for the parsing. (Useful for not parsing an entire page until some property is checked.)
  # @see Page#finish_processing
  def get_next_page(opts = {})
    node = @reader.next
    if node.name == 'page' && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
      xml = Nokogiri::XML.parse("<page> #{node.inner_xml} </page>").first_element_child
      WikiParser::Page.new({ node: xml, language: @language }.merge(opts))
    else
      get_next_page(opts)
    end
  rescue StopIteration, NoMethodError
    nil
  end
end
