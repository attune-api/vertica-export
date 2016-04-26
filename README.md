## Vertica to JSON Exporter

This is a small Ruby script that takes transforms the results of a Vertica SQL query into JSON. The results are output as one JSON object per row in the results. The column names from the query result are used as the keys for each JSON entry.

### Configuration

Database connection parameters are specifed in the `vertica_config.json` file:

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
Usage: vertica_export DESTFILE QUERY
Options
    -c, --config PATH                Configuration file: configures Vertica connection parameters.
    -l, --log_file PATH              Full path to output log file
        --log-level LEVEL            Logger level configuration, Valid values are: DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN
    -h, --help                       help
```

### Example

`./vertica_export.rb inventory.json 'select * from public.inventory_fact'`

