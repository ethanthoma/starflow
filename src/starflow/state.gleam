import gleam/dynamic
import gleam/option

/// Represents the current state of a chain, including conversation history,
/// token usage statistics, and custom state data.
///
/// ## Fields
/// - `messages`: List of messages in the conversation (TODO: should be held in reverse)
/// - `usage`: Token usage statistics for the conversation
/// - `any`: Custom state data that can be of any type
///
/// ## Examples
///
/// ```gleam
/// // Simple counter state
/// type Counter {
///   Counter(value: Int)
/// }
/// let state = new(Counter(0))
///
/// // Game state
/// type GameState {
///   GameState(target: Int, guesses: List(Int))
/// }
/// let state = new(GameState(target: 42, guesses: []))
/// ```
///
pub type State(any) {
  State(messages: List(Message), usage: Usage, any: any)
}

/// Creates a new state with empty message history, zero usage, and the provided
/// custom state data.
///
/// ## Examples
///
/// ```gleam
/// // Initialize with a string
/// let state = new("initial data")
///
/// // Initialize with a custom type
/// type GameState { GameState(score: Int) }
/// let state = new(GameState(0))
/// ```
///
pub fn new(any: any) -> State(any) {
  let usage =
    Usage(
      input_tokens: 0,
      cache_creation_input_tokens: option.None,
      cache_read_input_tokens: option.None,
      output_tokens: 0,
    )

  State(messages: [], usage: usage, any: any)
}

/// Represents the reason why the model stopped generating output.
///
/// ## Variants
/// - `EndTurn`: Natural completion of the response
/// - `MaxTokens`: Reached maximum token limit
/// - `StopSequence`: Encountered a stop sequence
/// - `ToolUse`: Stopped to use a tool
///
pub type StopReason {
  EndTurn
  MaxTokens
  StopSequence
  ToolUse
}

/// Tracks token usage statistics for the conversation.
///
/// ## Fields
/// - `input_tokens`: Number of tokens in the input
/// - `cache_creation_input_tokens`: Optional tokens used in cache creation
/// - `cache_read_input_tokens`: Optional tokens read from cache
/// - `output_tokens`: Number of tokens in the output
///
pub type Usage {
  Usage(
    input_tokens: Int,
    cache_creation_input_tokens: option.Option(Int),
    cache_read_input_tokens: option.Option(Int),
    output_tokens: Int,
  )
}

/// Represents a response from the model.
///
/// ## Fields
/// - `id`: Unique identifier for the response
/// - `content`: List of content blocks in the response
/// - `model`: Name of the model that generated the response
/// - `stop_reason`: Why the model stopped generating
/// - `usage`: Token usage statistics for this response
///
pub type Response {
  Response(
    id: String,
    content: List(Content),
    model: String,
    stop_reason: option.Option(StopReason),
    usage: Usage,
  )
}

/// Represents a message in the conversation.
///
/// ## Fields
/// - `role`: The role of the message sender (e.g., "user", "assistant")
/// - `content`: List of content blocks in the message
///
/// ## Examples
///
/// ```gleam
/// // Simple text message
/// Message(
///   role: "user",
///   content: [TextContent("Hello!")],
/// )
///
/// // Message with image
/// Message(
///   role: "user",
///   content: [
///     TextContent("What's in this image?"),
///     ImageContent(Base64Image(data, "image/jpeg")),
///   ],
/// )
/// ```
///
pub type Message {
  Message(role: String, content: List(Content))
}

/// Represents different types of content that can be in a message.
///
/// ## Variants
/// - `TextContent`: Simple text content
/// - `ImageContent`: Image data with source information
/// - `ToolContent`: Tool invocation with input parameters
///
/// ## Examples
///
/// ```gleam
/// // Text content
/// TextContent("Hello, world!")
///
/// // Image content
/// ImageContent(Base64Image(base64_data, "image/jpeg"))
///
/// // Tool content
/// ToolContent(
///   id: "calc_123",
///   name: "calculator",
///   input: dynamic.from_json("{\"operation\": \"add\", \"numbers\": [1, 2]}"),
/// )
/// ```
///
pub type Content {
  TextContent(text: String)
  ImageContent(source: ImageSource)
  ToolContent(id: String, name: String, input: dynamic.Dynamic)
}

/// Represents the source of an image in image content.
///
/// ## Variants
/// - `Base64Image`: Base64-encoded image data with media type
///
/// ## Examples
///
/// ```gleam
/// Base64Image(
///   data: "iVBORw0KGgoAAAANSU...",
///   media_type: "image/jpeg",
/// )
/// ```
///
pub type ImageSource {
  Base64Image(data: String, media_type: String)
}
