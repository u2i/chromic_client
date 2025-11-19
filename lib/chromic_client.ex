defmodule ChromicClient do
  @moduledoc """
  A client library that emulates the ChromicPDF API.

  In development mode (or when configured), it can fallback to using ChromicPDF directly.
  In production mode, it makes HTTP requests to the chrome_service REST API.

  ## Configuration

  Configure in your config.exs:

      config :chromic_client,
        mode: :api,  # or :chromic_pdf for direct ChromicPDF usage
        api_url: "http://localhost:8080"

  ## Examples

      # Print HTML to PDF
      {:ok, pdf} = ChromicClient.print_to_pdf({:html, "<h1>Hello</h1>"})

      # Print to file
      :ok = ChromicClient.print_to_pdf({:html, "<h1>Hello</h1>"}, output: "output.pdf")

      # Print to PDF/A
      {:ok, pdfa} = ChromicClient.print_to_pdfa({:html, "<h1>Hello</h1>"})

      # Convert existing PDF to PDF/A
      {:ok, pdfa} = ChromicClient.convert_to_pdfa("input.pdf")

      # Capture screenshot
      {:ok, png} = ChromicClient.capture_screenshot({:html, "<h1>Hello</h1>"})
  """

  @type source :: {:html, String.t()} | {:url, String.t()}
  @type source_and_options :: {source(), keyword()}
  @type blob :: binary()
  @type print_option ::
          {:output, Path.t()}
          | {:print_to_pdf_options, map()}
          | {:landscape, boolean()}
          | {:print_background, boolean()}
          | {:scale, float()}
          | {:paper_width, float()}
          | {:paper_height, float()}
          | {:margin_top, float()}
          | {:margin_bottom, float()}
          | {:margin_left, float()}
          | {:margin_right, float()}
  @type screenshot_option ::
          {:output, Path.t()}
          | {:width, integer()}
          | {:height, integer()}
          | {:full_page, boolean()}

  @doc """
  Prints HTML content to PDF.

  ## Options

    * `:output` - Path to save the PDF file. If not provided, returns `{:ok, binary}}`
    * `:landscape` - Print in landscape mode (default: false)
    * `:print_background` - Print background graphics (default: true)
    * `:scale` - Scale of the webpage rendering (default: 1.0)
    * `:paper_width` - Paper width in inches (default: 8.5)
    * `:paper_height` - Paper height in inches (default: 11)
    * `:margin_top` - Top margin in inches (default: 0.4)
    * `:margin_bottom` - Bottom margin in inches (default: 0.4)
    * `:margin_left` - Left margin in inches (default: 0.4)
    * `:margin_right` - Right margin in inches (default: 0.4)

  ## Examples

      {:ok, pdf} = ChromicClient.print_to_pdf({:html, "<h1>Hello</h1>"})
      :ok = ChromicClient.print_to_pdf({:html, "<h1>Hello</h1>"}, output: "hello.pdf")
  """
  @spec print_to_pdf(source() | source_and_options() | [source_and_options()], [print_option()]) ::
          {:ok, blob()} | :ok | {:error, term()}
  def print_to_pdf(input, opts \\ [])

  def print_to_pdf(sources, opts) when is_list(sources) do
    # Handle multiple sources - for now, just use the first one
    # In a full implementation, you'd need to merge PDFs
    case sources do
      [first | _] -> print_to_pdf(first, opts)
      [] -> {:error, :no_sources}
    end
  end

  def print_to_pdf({source_type, content}, opts) when source_type in [:html, :url] do
    case get_mode() do
      :chromic_pdf -> delegate_to_chromic_pdf(:print_to_pdf, {source_type, content}, opts)
      :api -> call_api(:print, content, opts)
    end
  end

  def print_to_pdf({{source_type, content}, source_opts}, opts)
      when source_type in [:html, :url] do
    merged_opts = Keyword.merge(source_opts, opts)
    print_to_pdf({source_type, content}, merged_opts)
  end

  @doc """
  Prints HTML content to PDF/A format.

  Accepts the same options as `print_to_pdf/2`.

  ## Examples

      {:ok, pdfa} = ChromicClient.print_to_pdfa({:html, "<h1>Hello</h1>"})
      :ok = ChromicClient.print_to_pdfa({:html, "<h1>Hello</h1>"}, output: "hello.pdf")
  """
  @spec print_to_pdfa(source() | source_and_options() | [source_and_options()], [print_option()]) ::
          {:ok, blob()} | :ok | {:error, term()}
  def print_to_pdfa(input, opts \\ [])

  def print_to_pdfa(sources, opts) when is_list(sources) do
    case sources do
      [first | _] -> print_to_pdfa(first, opts)
      [] -> {:error, :no_sources}
    end
  end

  def print_to_pdfa({source_type, content}, opts) when source_type in [:html, :url] do
    case get_mode() do
      :chromic_pdf -> delegate_to_chromic_pdf(:print_to_pdfa, {source_type, content}, opts)
      :api -> call_api(:print_pdfa, content, opts)
    end
  end

  def print_to_pdfa({{source_type, content}, source_opts}, opts)
      when source_type in [:html, :url] do
    merged_opts = Keyword.merge(source_opts, opts)
    print_to_pdfa({source_type, content}, merged_opts)
  end

  @doc """
  Converts an existing PDF to PDF/A format.

  ## Options

    * `:output` - Path to save the PDF/A file. If not provided, returns `{:ok, binary}`
    * `:pdfa_version` - PDF/A version (default: "3b")

  ## Examples

      {:ok, pdfa} = ChromicClient.convert_to_pdfa("input.pdf")
      :ok = ChromicClient.convert_to_pdfa("input.pdf", output: "output.pdf")
  """
  @spec convert_to_pdfa(Path.t() | binary(), keyword()) :: {:ok, blob()} | :ok | {:error, term()}
  def convert_to_pdfa(pdf_input, opts \\ []) do
    pdf_binary =
      case pdf_input do
        path when is_binary(path) ->
          if File.exists?(path) do
            File.read!(path)
          else
            # Assume it's already binary PDF content
            path
          end
      end

    case get_mode() do
      :chromic_pdf -> delegate_to_chromic_pdf(:convert_to_pdfa, pdf_binary, opts)
      :api -> call_api(:convert_pdfa, pdf_binary, opts)
    end
  end

  @doc """
  Captures a screenshot of HTML content.

  ## Options

    * `:output` - Path to save the screenshot. If not provided, returns `{:ok, binary}`
    * `:width` - Viewport width in pixels (default: 1280)
    * `:height` - Viewport height in pixels (default: 720)
    * `:full_page` - Capture full page screenshot (default: false)

  ## Examples

      {:ok, png} = ChromicClient.capture_screenshot({:html, "<h1>Hello</h1>"})
      :ok = ChromicClient.capture_screenshot({:html, "<h1>Hello</h1>"}, output: "screenshot.png")
  """
  @spec capture_screenshot(source() | source_and_options(), [screenshot_option()]) ::
          {:ok, blob()} | :ok | {:error, term()}
  def capture_screenshot(input, opts \\ [])

  def capture_screenshot({source_type, content}, opts) when source_type in [:html, :url] do
    case get_mode() do
      :chromic_pdf -> delegate_to_chromic_pdf(:capture_screenshot, {source_type, content}, opts)
      :api -> call_api(:screenshot, content, opts)
    end
  end

  def capture_screenshot({{source_type, content}, source_opts}, opts)
      when source_type in [:html, :url] do
    merged_opts = Keyword.merge(source_opts, opts)
    capture_screenshot({source_type, content}, merged_opts)
  end

  # Private functions

  defp get_mode do
    Application.get_env(:chromic_client, :mode, :api)
  end

  defp get_api_url do
    Application.get_env(:chromic_client, :api_url, "http://localhost:8080")
  end

  defp delegate_to_chromic_pdf(function, input, opts) do
    if Code.ensure_loaded?(ChromicPDF) do
      apply(ChromicPDF, function, [input, opts])
    else
      {:error, :chromic_pdf_not_available,
       "ChromicPDF is not available. Install it or switch to :api mode."}
    end
  end

  defp call_api(endpoint, content, opts) do
    url = get_api_url() <> "/v1/#{endpoint}"

    # Build request body
    body =
      case endpoint do
        :convert_pdfa ->
          %{pdf: content, options: build_options(opts)}

        _ ->
          %{html: content, options: build_options(opts)}
      end

    headers = [{"Content-Type", "application/json"}]
    json_body = Jason.encode!(body)

    case HTTPoison.post(url, json_body, headers, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        handle_response(response_body, opts)

      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        {:error, "API returned status #{status_code}: #{error_body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp build_options(opts) do
    opts
    |> Enum.reject(fn {key, _} -> key == :output end)
    |> Map.new()
  end

  defp handle_response(binary, opts) do
    case Keyword.get(opts, :output) do
      nil ->
        {:ok, binary}

      path ->
        case File.write(path, binary) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end
end
