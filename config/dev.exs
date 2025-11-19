import Config

# In development, you can choose to use ChromicPDF directly
# to avoid needing to run the chrome_service container
config :chromic_client,
  mode: :chromic_pdf  # or :api to use the REST service

# If using ChromicPDF in development, configure it
# config :chromic_pdf,
#   chromium: [
#     executable: System.get_env("CHROME_EXECUTABLE", "/usr/bin/chromium-browser")
#   ]
