require 'csv'
require 'open-uri'

abort "Wrong number of arguments (given #{ARGV.length}, expected 1)" if ARGV.length != 1

URL_FORMAT = %r{^((http|https)://)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?/.*)?$}ix.freeze
PROTOCOL_FORMAT = %r{^(http|https)\://}.freeze
HEADERS = %w[URL RESULT].freeze
FILE_NAME = 'output.csv'.freeze

File.delete(FILE_NAME) if File.exist?(FILE_NAME)

begin
  data_file = CSV.read(
    File.open(ARGV[0]),
    encoding: 'UTF-8',
    headers: true,
    header_converters: :symbol,
    converters: :all
  )
rescue
  abort 'Error while reading the file.'
end

CSV.open(FILE_NAME, 'wb') do |csv|
  csv << HEADERS

  data_file.map do |line|
    Thread.new do
      csv << [line[:url], 'wrong format'] && next unless line[:url] =~ URL_FORMAT

      url = line[:url] =~ PROTOCOL_FORMAT ? line[:url] : "http://#{line[:url]}"

      begin
        URI.parse(url).read
      rescue => e
        csv << [line[:url], "invalid or something was wrong: #{e.message}"]
      else
        csv << [line[:url], 'valid']
      end
    end
  end.each(&:join)
end
