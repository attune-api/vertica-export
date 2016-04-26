#!/usr/bin/env ruby
require 'logger'
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
  opt.on("-l", "--log-file PATH", "Full path to output log file") do |logfile|
    @options[:logfile] = logfile
  end
  opt.on("--log-level LEVEL", "Logger level configuration, Valid values are: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN") do |level|
    @options[:loglevel] = level.to_sym
  end
  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end
end

opt_parser.parse!

if @options[:logfile]
  file = open(@options[:logfile], 'a')
  file.sync = true #defence against broken logs, allow to tail -f the file
  @logger = Logger.new(file)
else
  @logger = Logger.new STDOUT
end
@logger.datetime_format = Time.now.strftime "%Y-%m-%dT%H:%M:%S"
@logger.formatter = proc do |severity, datetime, progname, msg|
   "#{Process.pid} #{self.class.name} #{datetime} #{severity}: #{msg}\n"
end
@logger.level = @options[:loglevel] ? Logger.const_get @options[:loglevel] :  Logger::INFO

vertica_config = JSON.parse(@options[:config] ? File.read( @options[:config]) : File.join(File.dirname(__FILE__), 'vertica_config.json'))
connection = Vertica.connect(vertica_config)

if (ARGV.size < 2)
  puts "Missing required argument."
  puts opt_parser
  exit 1
end

if (ARGV.size > 2)
  puts "Too many arguments."
  puts opt_parser
  exit 1
end

output_file = ARGV[0]
query = ARGV[1]

@logger.info "Exporting query results to #{output_file}"
@logger.debug "Query is: #{query}"

start = Time.now

output = File.open(output_file, 'w')

row_count = 0
connection.query(query) do |row|
  output << row.update(row) { |_,v| ( v.is_a?(String) && !v.valid_encoding? ) ? v.chars.select(&:valid_encoding?).join : v}.to_json
  output << "\n"
  row_count += 1
  @logger.debug("Processed #{row_count} rows") if (row_count % 10000 == 0)
end

output.close

@logger.info "Completed export, processed #{row_count} rows"
@logger.info "Took #{Time.now - start}"
