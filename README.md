# ChromicClient

An Elixir client library that emulates the ChromicPDF API while delegating to a REST API service or falling back to ChromicPDF directly.

## Features

- **Drop-in replacement** for ChromicPDF with the same API
- **Development fallback** - use ChromicPDF directly in dev mode
- **Production isolation** - use REST API to isolate Chrome in a separate container
- **Flexible configuration** - switch between modes with config

## Installation

Add `chromic_client` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chromic_client, path: "../chromic_client"}
    # In dev/test, optionally add ChromicPDF for fallback
    # {:chromic_pdf, "~> 1.17", only: [:dev, :test]}
  ]
end
```

## Configuration

### Development (using ChromicPDF directly)

```elixir
# config/dev.exs
config :chromic_client,
  mode: :chromic_pdf

config :chromic_pdf,
  chromium: [
    executable: System.get_env("CHROME_EXECUTABLE", "/usr/bin/chromium-browser")
  ]
```

### Production (using REST API)

```elixir
# config/prod.exs
config :chromic_client,
  mode: :api,
  api_url: System.get_env("CHROME_SERVICE_URL", "http://chrome-service:8080")
```

## Usage

The API is identical to ChromicPDF:

```elixir
# Print HTML to PDF
{:ok, pdf} = ChromicClient.print_to_pdf({:html, "<h1>Hello World</h1>"})

# Save to file
:ok = ChromicClient.print_to_pdf({:html, "<h1>Hello</h1>"}, output: "hello.pdf")

# Print to PDF/A
{:ok, pdfa} = ChromicClient.print_to_pdfa({:html, "<h1>Hello</h1>"})

# Convert existing PDF to PDF/A
{:ok, pdfa} = ChromicClient.convert_to_pdfa("input.pdf")

# Capture screenshot
{:ok, png} = ChromicClient.capture_screenshot({:html, "<h1>Hello</h1>"})

# With options
{:ok, pdf} = ChromicClient.print_to_pdf(
  {:html, "<h1>Hello</h1>"},
  landscape: true,
  print_background: true,
  margin_top: 0.5
)

# Full page screenshot
{:ok, png} = ChromicClient.capture_screenshot(
  {:html, "<html><body><h1>Page 1</h1><div style='height: 2000px'>Tall content</div></body></html>"},
  full_page: true
)
```

## Migrating from ChromicPDF

Simply replace `ChromicPDF` with `ChromicClient` in your code:

```elixir
# Before
ChromicPDF.print_to_pdf({:html, content}, opts)

# After
ChromicClient.print_to_pdf({:html, content}, opts)
```

Set the configuration mode based on your environment, and you're done!

## Running the Chrome Service

See the [chrome_service README](../chrome_service/README.md) for instructions on running the REST API service.

### Using Docker Compose

From the root directory:

```bash
docker-compose up chrome-service
```

The service will be available at `http://localhost:8080`.
