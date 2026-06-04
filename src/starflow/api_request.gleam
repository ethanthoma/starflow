import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/result
import gleam/string

import starflow/model
import starflow/providers
import starflow/providers/anthropic
import starflow/providers/ollama
import starflow/state
import starflow/tool

/// Represents possible errors that can occur during API requests.
///
/// ## Variants
/// - `NetworkError`: Connection or HTTP-related errors with error message
/// - `DecodingError`: Failed to decode request URL or response body
/// - `InvalidResponse`: Received non-200 status code with status and body
///
pub type APIError {
  NetworkError(String)
  DecodingError
  InvalidResponse(Int, String)
}

/// Creates a new message by sending a request to the model's provider.
///
/// The request URL, headers, body encoding, and response decoding are all
/// chosen based on `model.provider`, so the same `messages`/`tools` work
/// unchanged across providers.
///
/// ## Returns
/// A Result containing either:
/// - `Ok(Response)`: The successful API response
/// - `Error(APIError)`: An error that occurred during the request
///
pub fn create_message(
  model: model.Model,
  messages: List(state.Message),
  tools: List(tool.Tool),
) -> Result(state.Response, APIError) {
  case model.provider {
    providers.Anthropic(api_key) ->
      send(
        anthropic.endpoint(),
        anthropic.headers(api_key),
        anthropic.encode(model, messages, tools),
        anthropic.response(),
      )
    providers.Ollama(host) ->
      send(
        ollama.endpoint(host),
        ollama.headers(),
        ollama.encode(model, messages, tools),
        ollama.response(),
      )
  }
}

fn send(
  endpoint: String,
  headers: List(#(String, String)),
  body: json.Json,
  decoder: decode.Decoder(state.Response),
) -> Result(state.Response, APIError) {
  use req <- result.try(
    request.to(endpoint) |> result.map_error(fn(_) { DecodingError }),
  )

  let req =
    list.fold(headers, req, fn(req, header) {
      request.set_header(req, header.0, header.1)
    })
    |> request.set_method(http.Post)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) { err |> string.inspect |> NetworkError }),
  )

  case resp.status {
    200 ->
      json.parse(resp.body, decoder)
      |> result.map_error(fn(_) { DecodingError })
    status -> Error(InvalidResponse(status, resp.body))
  }
}
