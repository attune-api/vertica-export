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
    -q, --quiet                      Quiet mode; eliminate informational messages.
    -h, --help                       help
```

### Example

`./vertica_export.rb inventory.json 'select * from public.inventory_fact'`

