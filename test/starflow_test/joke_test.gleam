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

pub fn test_case() {
  use env_api_key <- result.try(
    envoy.get("ANTHROPIC_API_KEY")
    |> result.replace_error("api key not set!"),
  )
  let api_key = api_key.new(providers.Anthropic, env_api_key)

  let model = model.new(api_key)

  let prompt = fn(state) {
    let joke_query = "Tell me a joke."

    [state.TextContent(joke_query)]
  }

  let parser = fn(state, response: state.Response, _tool_uses) {
    let ai_response = {
      let contents = response.content
      let assert Ok(content) = list.last(contents)
      let assert state.TextContent(text_content) = content
      text_content
    }

    state.State(..state, any: option.Some(ai_response))
  }

  let flow =
    starflow.new(model)
    |> starflow.with_prompt(prompt)
    |> starflow.with_parser(parser)

  let state = option.None |> state.new
  use state <- result.try(
    starflow.invoke(state, flow) |> result.map_error(string.inspect),
  )

  use value <- given.some(state.any, fn() { Error("result is empty") })

  io.println("The joke is \n\"" <> value <> "\"")

  Ok(value)
}
