import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/string

import envoy
import prng/random
import prng/seed

import starflow
import starflow/api_key
import starflow/model
import starflow/providers
import starflow/state
import starflow/transform

pub type GameState {
  GameState(target: Int, guesses: List(Int), won: Bool)
}

type State =
  state.State(GameState)

pub fn test_case() -> Result(State, String) {
  let seed = seed.random()

  use env_api_key <- result.try(
    envoy.get("ANTHROPIC_API_KEY")
    |> result.replace_error("api key not set!"),
  )

  let flow =
    api_key.new(providers.Anthropic, env_api_key)
    |> model.new
    |> starflow.new
    |> starflow.with_prompt(prompt)
    |> starflow.with_parser(parser)

  let state =
    random.int(1, 10)
    |> random.sample(seed)
    |> GameState(guesses: [], won: False)
    |> state.new
  use state <- result.try(state |> run(flow))

  Ok(state)
}

fn run(state: State, flow) -> Result(State, String) {
  use state <- result.try(
    starflow.invoke(state, flow) |> result.map_error(string.inspect),
  )

  case state.any {
    GameState(won: True, ..) -> {
      io.println(
        "Claude correctly guessed "
        <> string.inspect(state.any.target)
        <> " and won!",
      )
      Ok(state)
    }
    GameState(guesses: guesses, ..) -> {
      case list.length(guesses) >= 5 {
        True -> {
          io.println(
            "Claude failed more than "
            <> string.inspect(state.any.guesses)
            <> " times...good luck next time!",
          )
          Ok(state)
        }
        False -> {
          let assert Ok(last_guess) = list.first(state.any.guesses)

          io.println(
            "Oops, the guess "
            <> string.inspect(last_guess)
            <> " was incorrect.  Try again!",
          )
          run(state, flow)
        }
      }
    }
  }
}

fn prompt(state: state.State(GameState)) {
  let game_state = state.any

  let previous_guesses = case game_state.guesses {
    [] -> ""
    guesses ->
      "\nPrevious guesses: "
      <> string.join(list.map(guesses, int.to_string), ", ")
  }

  let prompt_text =
    "I'm thinking of a number between 1 and 10."
    <> previous_guesses
    <> "\nMake a guess using this exact format: 'GUESS: <number>'"

  [state.TextContent(prompt_text)]
}

fn parser(state: State, response, tool_uses) -> State {
  let state = transform.parser_default(state, response, tool_uses)

  let assert Ok(regex) = regex.from_string("GUESS: (\\d+)")
  let content = case response.content {
    [state.TextContent(text)] -> text
    _ -> ""
  }

  let guess = case regex.scan(regex, content) {
    [regex.Match(_, [option.Some(num)]), ..] ->
      case int.parse(num) {
        Ok(n) -> option.Some(n)
        Error(_) -> option.None
      }
    _ -> option.None
  }

  let any = case guess {
    option.Some(n) -> {
      let guesses = [n, ..state.any.guesses]
      let won = n == state.any.target
      GameState(target: state.any.target, guesses: guesses, won: won)
    }
    option.None -> state.any
  }

  state.State(..state, any:)
}
