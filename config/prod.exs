import Config

# In production, use the REST API service
config :chromic_client,
  mode: :api,
  api_url: System.get_env("CHROME_SERVICE_URL", "http://chrome-service:8080")
