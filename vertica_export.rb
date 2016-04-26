#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'json'
require 'optparse'
require 'vertica'

# Exports the results of a SQL query to Vertica as JSON

@options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: vertica_export.rb DESTFILE QUERY"
  opt.separator "Options"
  opt.on("-q", "--quiet", "Quiet mode; eliminate informational messages.") do
    @options[:quiet] = true
  end
  opt.on("-c", "--config PATH", "Configuration file: configures Vertica connection parameters.") do |path|
    @options[:config] = path
  end
  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end
end

opt_parser.parse!

def log(message)
  puts(message) unless @options[:quiet]
end

vertica_config = JSON.parse(@options[:config] ? File.read( @options[:config]) : File.join(File.dirname(__FILE__), 'vertica_config.json'))
connection = Vertica.connect(vertica_config)

if (ARGV.size < 2)
  puts "Missing required argument."
  puts opt_parser
  exit 1
end

if (ARGV.size > 2)
  log "Too many arguments."
  puts opt_parser
  exit 1
end

filename = ARGV[0]
query = ARGV[1]

log "Exporting query results to #{filename}: #{query}"
start = Time.now

output = File.open(filename, 'w')

row_count = 0
connection.query(query) do |row|
  output << row.to_json
  output << "\n"
  row_count += 1
  log("Processed #{row_count} rows") if (row_count % 10000 == 0)
end

output.close

log "Completed export, processed #{row_count} rows"
log "Took #{Time.now - start}"
