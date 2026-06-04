# Starflow ✨

[![Package Version](https://img.shields.io/hexpm/v/flow)](https://hex.pm/packages/starflow)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/starflow/)

Starflow is a Gleam library for building stateful chains of LLM interactions. It
provides a simple, type-safe way to create flows that transform state into
prompts, interact with language models, and parse responses back into state.

> [!NOTE]
>
> Supports Anthropic's Claude and Ollama (local LLMs, via its OpenAI-compatible
> API). Streaming is not yet supported.

## Installation

```sh
gleam add starflow
```

## Quick Start

Here's a simple example that asks Claude to tell a joke:

```gleam
import gleam/io
import gleam/result
import gleam/string
import envoy

import starflow
import starflow/model
import starflow/providers
import starflow/state

pub fn main() {
  let result = {
    // Setup provider and model
    use env_api_key <- result.try(
      envoy.get("ANTHROPIC_API_KEY")
      |> result.replace_error("api key not set!"),
    )
    let model = model.new(providers.anthropic(env_api_key))

    // Define prompt transformer
    let prompt = fn(state) {
      [state.TextContent("Tell me a joke.")]
    }

    // Create and execute flow
    let flow =
      starflow.new(model)
      |> starflow.with_prompt(prompt)

    let state = state.new(Nil)
    starflow.invoke(state, flow)
  }

  case result {
    Ok(state) -> io.println(string.inspect(state))
    Error(err) -> io.println_error(err)
  }
}
```

## Key Features

### State Management

- Type-safe state that can hold any custom data
- Automatic conversation history tracking
- Token usage statistics

### Transformers

- Custom prompt generation from state
- Flexible response parsing back to state
- Default transformers for simple use cases

### Provider Support

- Anthropic's Claude (hosted API)
- Ollama (local LLMs, via its OpenAI-compatible API), no API key required
- Each provider carries its own config, so swapping is a one-line change

```gleam
// Anthropic
let model = model.new(providers.anthropic(api_key))

// Local Ollama (defaults to http://localhost:11434)
let model =
  model.new(providers.ollama())
  |> model.with_name("llama3.2")

// Ollama on a custom host
let model = model.new(providers.ollama_at("http://gpu-box:11434"))
```

## Examples

See the [test directory](./test/starflow_test/) for examples!

## Common Patterns

### Simple Question-Answer

```gleam
let flow =
  starflow.new(model)
  |> starflow.with_prompt(fn(question) {
    [state.TextContent(question)]
  })

starflow.invoke(state.new("What is 2+2?"), flow)
```

### Stateful Interactions

```gleam
// Define custom state type
pub type GameState {
  GameState(target: Int, guesses: List(Int))
}

// Create game flow
let game_flow =
  starflow.new(model)
  |> starflow.with_prompt(fn(state: GameState) {
    [state.TextContent("Guess a number between 1 and " <> int.to_string(state.target))]
  })
  |> starflow.with_parser(fn(state, resp) {
    // Parse response and update game state
    let guess = parse_number(resp)
    state.State(..state, any: GameState(..state.any, guesses: [guess, ..state.any.guesses]))
  })
```

### Response Parsing

```gleam
let flow =
  starflow.new(model)
  |> starflow.with_parser(fn(state, resp) {
    case resp.content {
      [state.TextContent(text)] -> {
        // Process response text
        state.State(..state, any: process_text(text))
      }
      _ -> state
    }
  })
```

## Development

```sh
gleam run   # Run the project
```

## Coming Soon

- Chain composition for complex flows
- More sophisticated state management
- Additional provider support
- Streaming responses
- Tool usage support

## Documentation

For detailed documentation visit
[hexdocs.pm/starflow](https://hexdocs.pm/starflow).
