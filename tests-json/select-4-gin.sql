SELECT data FROM :json_table WHERE data @> '{"type": "service"}';