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

pub fn number_guess_test() -> Result(state.State(GameState), String) {
  let seed = seed.random()

  use env_api_key <- result.try(
    envoy.get("ANTHROPIC_API_KEY")
    |> result.replace_error("api key not set!"),
  )
  let api_key = api_key.new(providers.Anthropic, env_api_key)

  let generator = random.int(1, 10)
  let target = random.sample(generator, seed)
  let initial_state = GameState(target: target, guesses: [], won: False)

  let flow = flow(api_key)

  let result = run(state.new(initial_state), flow)

  case result {
    Ok(_) -> Nil
    Error(err) -> io.println_error(err)
  }

  result
}

fn run(
  state: state.State(GameState),
  flow: starflow.Flow(GameState),
) -> Result(state.State(GameState), String) {
  use state <- result.try(
    starflow.invoke(state, flow) |> result.map_error(string.inspect),
  )

  case state.any {
    GameState(won: True, ..) -> {
      io.debug(
        "Claude correctly guessed "
        <> string.inspect(state.any.target)
        <> " and won!",
      )
      Ok(state)
    }
    GameState(guesses: guesses, ..) -> {
      case list.length(guesses) >= 5 {
        True -> {
          io.debug(
            "Claude failed more than "
            <> string.inspect(state.any.guesses)
            <> " times...good luck next time!",
          )
          Ok(state)
        }
        False -> {
          let assert Ok(last_guess) = list.first(state.any.guesses)

          io.debug(
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

fn flow(api_key: api_key.APIKey) {
  let model = model.new(api_key)

  starflow.new(model)
  |> starflow.with_prompt(prompt)
  |> starflow.with_parser(parser)
}

fn prompt(game_state: GameState) {
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

fn parser(state: state.State(GameState), response) -> state.State(GameState) {
  let state = transform.parser_default(state, response)

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

  let game_state = case guess {
    option.Some(n) -> {
      let guesses = [n, ..state.any.guesses]
      let won = n == state.any.target
      GameState(target: state.any.target, guesses: guesses, won: won)
    }
    option.None -> state.any
  }

  state.State(..state, any: game_state)
}
