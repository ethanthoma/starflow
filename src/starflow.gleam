import gleam/list
import gleam/result

import starflow/api_request
import starflow/model
import starflow/state
import starflow/transform

pub type NoModel

pub type HasModel

/// Represents a flow of transformations from state to prompt to response and back to state.
///
/// ## Fields
/// - `model`: The model configuration for API requests
/// - `prompt`: Function to transform state into a prompt
/// - `parser`: Function to transform response back into state
///
/// ## Example
///
/// ```gleam
/// // Create a flow for a number guessing game
/// type GameState {
///   GameState(target: Int, guesses: List(Int))
/// }
///
/// let game_flow =
///   new(model)
///   |> with_prompt(fn(state) {
///     [state.TextContent("Guess a number between 1 and 10")]
///   })
///   |> with_parser(fn(state, resp) {
///     // Parse response and update game state
///     let guess = extract_guess(resp)
///     let new_guesses = [guess, ..state.any.guesses]
///     state.State(..state, any: GameState(..state.any, guesses: new_guesses))
///   })
/// ```
///
pub type Flow(any) {
  Flow(
    model: model.Model,
    prompt: transform.Prompt(any),
    parser: transform.Parser(any),
  )
}

/// Creates a new Flow with the given model and default transformers.
///
/// ## Examples
///
/// ```gleam
/// let flow = new(model)
/// // Creates a flow with:
/// // - The specified model
/// // - Default prompt transformer (string inspection)
/// // - Default response parser (message accumulation)
/// ```
///
pub fn new(model: model.Model) -> Flow(any) {
  Flow(
    model: model,
    prompt: transform.prompt_default,
    parser: transform.parser_default,
  )
}

/// Updates the model configuration of a Flow.
///
/// ## Examples
///
/// ```gleam
/// let updated_flow =
///   flow
///   |> with_model(new_model)
/// ```
///
pub fn with_model(flow: Flow(any), model: model.Model) -> Flow(any) {
  Flow(model: model, prompt: flow.prompt, parser: flow.parser)
}

/// Sets a custom prompt transformer for the Flow.
///
/// ## Examples
///
/// ```gleam
/// let flow =
///   new(model)
///   |> with_prompt(fn(state) {
///     [state.TextContent("Current count: " <> int.to_string(state))]
///   })
/// ```
///
pub fn with_prompt(flow: Flow(any), prompt: transform.Prompt(any)) -> Flow(any) {
  Flow(model: flow.model, prompt: prompt, parser: flow.parser)
}

/// Sets a custom response parser for the Flow.
///
/// ## Examples
///
/// ```gleam
/// let flow =
///   new(model)
///   |> with_parser(fn(state, resp) {
///     // Extract and process the response
///     case resp.content {
///       [state.TextContent(text)] -> {
///         let count = parse_number(text)
///         state.State(..state, any: count)
///       }
///       _ -> state
///     }
///   })
/// ```
///
pub fn with_parser(flow: Flow(any), parser: transform.Parser(any)) -> Flow(any) {
  Flow(model: flow.model, prompt: flow.prompt, parser: parser)
}

/// Executes one step of the Flow:
/// 1. Transforms state into a prompt using the prompt transformer
/// 2. Sends the prompt to the model
/// 3. Transforms the response back into state using the parser
///
/// ## Examples
///
/// ```gleam
/// // Simple counter flow
/// let counter_flow =
///   new(model)
///   |> with_prompt(fn(count) {
///     [state.TextContent("Add one to " <> int.to_string(count))]
///   })
///   |> with_parser(fn(state, resp) {
///     // Parse response to get new count
///     let new_count = state.any + 1
///     state.State(..state, any: new_count)
///   })
///
/// // Run one step
/// case invoke(state.new(0), counter_flow) {
///   Ok(new_state) -> // Handle updated state
///   Error(error) -> // Handle API error
/// }
/// ```
///
pub fn invoke(
  state: state.State(any),
  flow: Flow(any),
) -> Result(state.State(any), api_request.APIError) {
  let model = flow.model

  let prompt = flow.prompt

  let message = state.Message(role: "user", content: prompt(state.any))

  let messages = list.append(state.messages, [message])

  use resp <- result.try(api_request.create_message(model, messages))

  let state = flow.parser(state, resp)

  Ok(state)
}
