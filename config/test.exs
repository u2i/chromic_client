import Config

# In test, you can use ChromicPDF or a mock API
config :chromic_client,
  mode: :chromic_pdf,
  api_url: "http://localhost:8080"
