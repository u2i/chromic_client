import Config

# Configure ChromicClient to use the REST API by default
config :chromic_client,
  mode: :api,
  api_url: "http://localhost:8080"

# Import environment-specific config
import_config "#{config_env()}.exs"
