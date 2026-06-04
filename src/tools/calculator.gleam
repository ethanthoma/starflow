import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/result

import starflow/schema
import starflow/tool

type Operation {
  Add
  Subtract
  Multiply
  Divide
}

type Calculator {
  Calculator(Operation, Float, Float)
}

pub fn tool() -> tool.Tool {
  tool.Tool(
    name: "calculator",
    description: "Performs basic arithmetic calculations",
    schema: schema.object([
      schema.required(
        "operation",
        schema.enum(["add", "subtract", "multiply", "divide"]),
      ),
      schema.required("a", schema.number()),
      schema.required("b", schema.number()),
    ]),
    output: schema.number(),
    apply: apply,
  )
}

fn apply(input: dynamic.Dynamic) {
  use Calculator(op, a, b) <- result.map(decode.run(input, decoder()))

  case op {
    Add -> a +. b
    Subtract -> a -. b
    Multiply -> a *. b
    Divide -> a /. b
  }
  |> tool.Number
}

fn decoder() -> decode.Decoder(Calculator) {
  use op <- decode.field("operation", operation())
  use a <- decode.field("a", number())
  use b <- decode.field("b", number())
  decode.success(Calculator(op, a, b))
}

fn operation() -> decode.Decoder(Operation) {
  use name <- decode.then(decode.string)
  case name {
    "add" -> decode.success(Add)
    "subtract" -> decode.success(Subtract)
    "multiply" -> decode.success(Multiply)
    "divide" -> decode.success(Divide)
    _ -> decode.failure(Add, "Operation")
  }
}

fn number() -> decode.Decoder(Float) {
  decode.one_of(decode.float, [decode.int |> decode.map(int.to_float)])
}
