SELECT data FROM :json_table WHERE data @> '{"brand": "ACME"}';