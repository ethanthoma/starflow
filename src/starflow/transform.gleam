import gleam/list
import gleam/string

import starflow/state

/// A function that transforms the chain's state into a list of content blocks
/// that will be sent to the model as a prompt.
///
/// ## Examples
///
/// ```gleam
/// let simple_prompt = fn(state) {
///   [state.TextContent("Hello!")]
/// }
///
/// let template_prompt = fn(data: TemplateData) {
///   [state.TextContent("User name: " <> data.name)]
/// }
/// ```
///
pub type Prompt(any) =
  fn(any) -> List(state.Content)

/// Default prompt transformer that simply inspects the state and wraps it
/// in a TextContent block.
///
/// ## Examples
///
/// ```gleam
/// let state = "Hello"
/// prompt_default(state)  // Returns [TextContent("\"Hello\"")]
///
/// let state = 42
/// prompt_default(state)  // Returns [TextContent("42")]
/// ```
///
pub fn prompt_default(any) -> List(state.Content) {
  [state.TextContent(string.inspect(any))]
}

/// A function that updates the chain's state based on the model's response.
/// This allows for custom processing of the model's output and updating the
/// state accordingly.
///
/// ## Examples
///
/// ```gleam
/// let update_game = fn(state, response) {
///   // Extract guess from response
///   let guess = parse_guess(response.content)
///   // Update game state with new guess
///   state.State(..state, guesses: [guess, ..state.guesses])
/// }
///
/// let accumulate_summary = fn(state, response) {
///   // Add response to list of summaries
///   state.State(..state, summaries: [response.content, ..state.summaries])
/// }
/// ```
///
pub type Parser(any) =
  fn(state.State(any), state.Response) -> state.State(any)

/// Default parser transformer function that:
/// 1. Preserves the message history by appending the model's response
/// 2. Updates the usage information
/// 3. Maintains the existing state
///
/// This is useful when you just want to accumulate the conversation history
/// without any special processing of the responses.
///
/// ## Examples
///
/// ```gleam
/// let flow =
///   starflow.new(model)
///   |> starflow.with_parser(parser_default)
///
/// // Each response will be added to the message history
/// // and usage stats will be updated
/// ```
///
pub fn parser_default(
  state: state.State(any),
  last_response: state.Response,
) -> state.State(any) {
  let usage = last_response.usage

  let content = last_response.content

  let message = state.Message("assistant", content)

  state.State(
    ..state,
    messages: list.append(state.messages, [message]),
    usage: usage,
  )
}
