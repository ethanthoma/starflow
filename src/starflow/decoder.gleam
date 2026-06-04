import gleam/dynamic/decode
import gleam/option

import starflow/state

fn content() -> decode.Decoder(state.Content) {
  let text = {
    use text <- decode.field("text", decode.string)
    decode.success(state.TextContent(text))
  }

  let tool = {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use input <- decode.field("input", decode.dynamic)
    decode.success(state.ToolContent(id, name, input))
  }

  use variant <- decode.field("type", decode.string)
  case variant {
    "text" -> text
    "tool_use" -> tool
    _ -> decode.failure(state.TextContent(""), "Content")
  }
}

fn stop_reason() -> decode.Decoder(state.StopReason) {
  use reason <- decode.then(decode.string)
  case reason {
    "end_turn" -> decode.success(state.EndTurn)
    "max_tokens" -> decode.success(state.MaxTokens)
    "stop_sequence" -> decode.success(state.StopSequence)
    "tool_use" -> decode.success(state.ToolUse)
    _ -> decode.failure(state.EndTurn, "StopReason")
  }
}

fn usage() -> decode.Decoder(state.Usage) {
  use input_tokens <- decode.field("input_tokens", decode.int)
  use cache_creation_input_tokens <- decode.optional_field(
    "cache_creation_input_tokens",
    option.None,
    decode.optional(decode.int),
  )
  use cache_read_input_tokens <- decode.optional_field(
    "cache_read_input_tokens",
    option.None,
    decode.optional(decode.int),
  )
  use output_tokens <- decode.field("output_tokens", decode.int)
  decode.success(state.Usage(
    input_tokens:,
    cache_creation_input_tokens:,
    cache_read_input_tokens:,
    output_tokens:,
  ))
}

pub fn response() -> decode.Decoder(state.Response) {
  use id <- decode.field("id", decode.string)
  use content <- decode.field("content", decode.list(content()))
  use model <- decode.field("model", decode.string)
  use stop_reason <- decode.optional_field(
    "stop_reason",
    option.None,
    decode.optional(stop_reason()),
  )
  use usage <- decode.field("usage", usage())
  decode.success(state.Response(id:, content:, model:, stop_reason:, usage:))
}
