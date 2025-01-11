import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string

import envoy
import given

import starflow
import starflow/api_key
import starflow/model
import starflow/providers
import starflow/state
import starflow/tool
import starflow/transform
import tools/calculator

type State =
  state.State(option.Option(Float))

pub fn test_case() {
  use env_api_key <- result.try(
    envoy.get("ANTHROPIC_API_KEY")
    |> result.replace_error("api key not set!"),
  )

  let flow =
    providers.Anthropic
    |> api_key.new(env_api_key)
    |> model.new
    |> starflow.new
    |> starflow.with_prompt(prompt)
    |> starflow.with_parser(parser)
    |> starflow.with_tool(calculator.tool())

  let state = state.new(option.None)
  use state <- result.try(
    state
    |> starflow.invoke(flow)
    |> result.map_error(string.inspect),
  )

  use value <- given.some(state.any, fn() { Error("result is empty") })

  io.println("Result is " <> string.inspect(value))

  Ok(value)
}

fn prompt(_state: State) {
  let prompt_text = "What is 42 multiplied by 17? Use the calculator."

  io.println(prompt_text)

  [state.TextContent(prompt_text)]
}

fn parser(state: State, response, tool_uses) -> State {
  let state = transform.parser_default(state, response, tool_uses)

  let any = {
    use #(_, tool_result) <- option.then(
      list.last(tool_uses)
      |> option.from_result,
    )

    case tool_result {
      tool.Number(float) -> option.Some(float)
      _ -> option.None
    }
  }

  state.State(..state, any:)
}
