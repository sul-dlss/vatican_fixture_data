require 'nokogiri'
require 'fileutils'

# Run this file by running ruby tei_splitter.rb /path/to/tei/that/needs/to/be/split

##
# Splits (a very specific flavor of) TEI so that all TEI.2 elements with the same IDNO are
# grouped in the same tei.xml file within a directory with the IDNO in the name
class TeiSplitter
  attr_reader :input_tei_path
  def initialize(input_tei_path)
    @input_tei_path = input_tei_path
  end

  def tei_2s
    return to_enum(:tei_2s) unless block_given?

    tei.xpath('//TEI.2').each do |tei2|
      yield Tei2.new(tei2)
    end
  end

  class << self
    def write_output(input_tei_path)
      new(input_tei_path).tei_2s.group_by(&:idno).each do |idno, xml|
        write_xml_output(idno, xml)
      end
    end

    private

    def write_xml_output(idno, xml_array)
      FileUtils.mkdir_p("#{output_directory}/MSS_#{idno}")
      File.open("#{output_directory}/MSS_#{idno}/tei.xml", 'w') do |f|
        f.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>\n  #{xml_array.join("\n  ")}\n</root>"
      end
    end

    def output_directory
      File.dirname(__FILE__)
    end
  end

  private

  def tei
    @tei ||= Nokogiri::XML(File.read(input_tei_path))
  end

  class Tei2
    attr_reader :xml

    def initialize(xml)
      @xml = xml
    end

    def to_s
      xml.to_s
    end

    def idno
      xml.xpath('.//idno').text
    end
  end
end

TeiSplitter.write_output(ARGV[0])
