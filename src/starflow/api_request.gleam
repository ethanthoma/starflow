import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import gleam/string

import starflow/api_key
import starflow/decoder
import starflow/encoder
import starflow/model
import starflow/providers
import starflow/state

/// Represents possible errors that can occur during API requests.
///
/// ## Variants
/// - `NetworkError`: Connection or HTTP-related errors with error message
/// - `DecodingError`: Failed to decode request URL or response body
/// - `InvalidResponse`: Received non-200 status code with status and body
///
/// ## Examples
///
/// ```gleam
/// case create_message(model, messages) {
///   Error(NetworkError(msg)) -> // Handle network failure
///   Error(DecodingError) -> // Handle malformed response
///   Error(InvalidResponse(status, body)) -> // Handle API error response
///   Ok(response) -> // Handle successful response
/// }
/// ```
///
pub type APIError {
  NetworkError(String)
  DecodingError
  InvalidResponse(Int, String)
}

fn add_headers(
  req: request.Request(any),
  model: model.Model,
  api_key: api_key.APIKey,
) -> request.Request(any) {
  req
  |> request.set_header("content-type", "application/json")
  |> request.set_header("x-api-key", api_key.get(api_key))
  |> request.set_header("anthropic-version", providers.version(model.provider))
}

/// Creates a new message by sending a request to the model's API.
///
/// This function:
/// 1. Builds the request URL based on the provider
/// 2. Adds necessary headers
/// 3. Encodes the messages into the request body
/// 4. Sends the request
/// 5. Decodes the response
///
/// ## Arguments
/// - `model`: The model configuration to use
/// - `messages`: List of messages to send to the model
///
/// ## Returns
/// A Result containing either:
/// - `Ok(Response)`: The successful API response
/// - `Error(APIError)`: An error that occurred during the request
///
/// ## Examples
///
/// ```gleam
/// // Simple message creation
/// let messages = [
///   state.Message(
///     role: "user",
///     content: [state.TextContent("Hello!")],
///   )
/// ]
///
/// case create_message(model, messages) {
///   Ok(response) -> handle_response(response)
///   Error(error) -> handle_error(error)
/// }
///
/// // With image content
/// let messages = [
///   state.Message(
///     role: "user",
///     content: [
///       state.TextContent("What's in this image?"),
///       state.ImageContent(source: image_source),
///     ],
///   )
/// ]
///
/// create_message(model, messages)
/// ```
///
pub fn create_message(model: model.Model, messages: List(state.Message)) {
  use req <- result.try(
    request.to(string.concat([providers.url(model.provider), "/messages"]))
    |> result.map_error(fn(_) { DecodingError }),
  )

  let req =
    req
    |> request.set_method(http.Post)
    |> add_headers(model, model.api_key)
    |> request.set_body(encoder.encode(model, messages) |> json.to_string)

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(err) { err |> string.inspect |> NetworkError }),
  )

  case resp.status {
    200 -> {
      use response <- result.try(
        json.decode(resp.body, decoder.response)
        |> result.map_error(fn(_) { DecodingError }),
      )

      Ok(response)
    }
    _ -> Error(NetworkError(string.inspect(resp.status)))
  }
}
