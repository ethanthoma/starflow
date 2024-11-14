import gleam/dynamic
import gleam/result

import starflow/state

fn content_type(
  content: dynamic.Dynamic,
) -> Result(List(state.Content), List(dynamic.DecodeError)) {
  content
  |> dynamic.list(
    of: dynamic.any(of: [
      dynamic.decode2(
        fn(_, text) { state.TextContent(text) },
        dynamic.field(named: "type", of: dynamic.string),
        dynamic.field(named: "text", of: dynamic.string),
      ),
      dynamic.decode4(
        fn(_, id, name, input) { state.ToolContent(id, name, input) },
        dynamic.field(named: "type", of: dynamic.string),
        dynamic.field(named: "id", of: dynamic.string),
        dynamic.field(named: "name", of: dynamic.string),
        dynamic.field(named: "input", of: dynamic.dynamic),
      ),
    ]),
  )
}

fn stop_reason(
  stop_reason: dynamic.Dynamic,
) -> Result(state.StopReason, List(dynamic.DecodeError)) {
  stop_reason
  |> dynamic.string
  |> result.then(fn(reason: String) {
    case reason {
      "end_turn" -> Ok(state.EndTurn)
      "max_tokens" -> Ok(state.MaxTokens)
      "stop_sequence" -> Ok(state.StopSequence)
      "tool_use" -> Ok(state.ToolUse)
      _ -> Error([dynamic.DecodeError("StopReason", "String", [])])
    }
  })
}

fn usage(
  usage: dynamic.Dynamic,
) -> Result(state.Usage, List(dynamic.DecodeError)) {
  usage
  |> dynamic.decode4(
    state.Usage,
    dynamic.field(named: "input_tokens", of: dynamic.int),
    dynamic.optional_field(
      named: "cache_creation_input_tokens",
      of: dynamic.int,
    ),
    dynamic.optional_field(named: "cache_read_input_tokens", of: dynamic.int),
    dynamic.field(named: "output_tokens", of: dynamic.int),
  )
}

pub fn response(
  body: dynamic.Dynamic,
) -> Result(state.Response, List(dynamic.DecodeError)) {
  body
  |> dynamic.decode5(
    state.Response,
    dynamic.field(named: "id", of: dynamic.string),
    dynamic.field(named: "content", of: content_type),
    dynamic.field(named: "model", of: dynamic.string),
    dynamic.optional_field(named: "stop_reason", of: stop_reason),
    dynamic.field(named: "usage", of: usage),
  )
}
