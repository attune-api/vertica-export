## Vertica to JSON Exporter

This is a small Ruby script that takes transforms the results of a Vertica SQL query into JSON. The results are output as one JSON object per row in the results. The column names from the query result are used as the keys for each JSON entry.

### Configuration

Database connection parameters are specified in the `vertica_config.json` file:

```
{
    "host" : "localhost",
    "user" : "dbadmin",
    "password" : "password",
    // "ssl": "false",
    "port": 5433
}
```

### Usage

```
➜  vertica-export  ./vertica_export -h
Usage: vertica_export.rb -o|--output-file OUTPUT_FILE_NAME -f|--query-file QUERY_FILE or QUERY_STRING
Options
    -c, --config PATH                Configuration file: configures Vertica connection parameters.
    -f, --query-file QUERY_FILE      Specify the file containing the query to be run
    -l, --log_file PATH              Full path to output log file
        --log-level LEVEL            Logger level configuration, Valid values are: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN
        --drop-invalid-characters    Drop invalid characters from string column values of the result-set
    -r, --retry-count COUNT          Number of retries before giving up
    -t, --timeout SECONDS            Timeout (in seconds) to wait for 1st row
    -h, --help                       help
```

### Examples

```
./vertica_export.rb -o /path/to/output.json 'select * from public.inventory_fact'
./vertica_export.rb -o /path/to/output.json -f/path/to/query.sql`
./vertica_export.rb -r 2 -t 4200 --log-level DEBUG -o /path/to/output.json -f/path/to/query.sql`
```
