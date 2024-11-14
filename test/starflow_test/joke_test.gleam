import gleam/io
import gleam/result
import gleam/string

import envoy

import starflow
import starflow/api_key
import starflow/model
import starflow/providers
import starflow/state

pub fn joke_test() {
  let result = {
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

    let flow =
      starflow.new(model)
      |> starflow.with_prompt(prompt)

    let state = state.new(Nil)

    use state <- result.try(
      starflow.invoke(state, flow) |> result.map_error(string.inspect),
    )

    Ok(state)
  }

  case result {
    Ok(state) -> io.println(string.inspect(state))
    Error(err) -> io.println_error(err)
  }
}
