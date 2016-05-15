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
  opt.banner = "Usage: vertica_export.rb -o|--output-file OUTPUT_FILE_NAME QUERY"
  opt.separator "Options"
  opt.on("-c", "--config PATH", "Configuration file: configures Vertica connection parameters.") do |path|
    @options[:config] = path
  end
  opt.on("-l", "--log-file PATH", "Full path to output log file") do |logfile|
    @options[:logfile] = logfile
  end
  opt.on("--log-level LEVEL", "Logger level configuration, Valid values are: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN") do |level|
    @options[:loglevel] = level.to_sym
  end
  opt.on("-o", "--output-file PATH", "Full path where query results will be stored") do |outfile|
    if File.directory?(outfile)
      raise "Output path cannot be a directory"
    else
      @options[:outfile] = outfile
    end
  end
  opt.on("-r", "--retry-count COUNT", Integer, "number of retries when query fails") do |retry_count|
    @options[:retry_count] = retry_count
  end
  opt.on("-h","--help","help") do
    puts opt_parser
    exit
  end
end

opt_parser.parse!
@options[:retry_count] ||= 3

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
@logger.level = @options[:loglevel] ? Logger.const_get("#{@options[:loglevel]}") :  Logger::INFO

vertica_config_file = @options[:config] ? @options[:config] : File.join(File.dirname(__FILE__), 'vertica_config.json')
if File.exist?(vertica_config_file)
  vertica_config = JSON.parse(File.read(vertica_config_file))
else
  raise "Cannot read #{vertica_config_file}, please make sure that file exists and that the user has sufficient permissions to read it"
end

connection = Vertica.connect(vertica_config)

if (ARGV.size > 1)
  puts "Too many arguments."
  puts opt_parser
  exit 1
end

query = ARGV[0]

@logger.info "Exporting query results to #{@options[:outfile]}"
@logger.debug "Query is: #{query}"

start = Time.now

output = File.open(@options[:outfile], 'w')

retry_count = 0
begin
  row_count = 0
  connection.query(query) do |row|
    output << row.update(row) { |_,v| ( v.is_a?(String) && !v.valid_encoding? ) ? v.chars.select(&:valid_encoding?).join : v}.to_json
    output << "\n"
    row_count += 1
    @logger.debug("Processed #{row_count} rows") if (row_count % 10000 == 0)
  end
rescue Vertica::Error => e
  @logger.error("Exception thrown: #{e.message}, Retry count=#{@options[:retry_count]}, current count=#{retry_count}")
  retry_count+=1
  if retry_count < @options[:retry_count]
    output.truncate(0)
    connection.reset_connection
    retry
  else
    raise e
  end
end

output.close

@logger.info "Completed export, processed #{row_count} rows"
@logger.info "Took #{Time.now - start}"
