UPDATE :json_table SET data = jsonb_set(data, '{limits, data, extra}', '"Extra Data"') WHERE (data->>'type') = 'service';