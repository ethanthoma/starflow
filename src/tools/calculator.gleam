import gleam/dynamic
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
  use Calculator(op, a, b) <- result.map(decoder(input))

  case op {
    Add -> a +. b
    Subtract -> a -. b
    Multiply -> a *. b
    Divide -> a /. b
  }
  |> tool.Number
}

fn decoder(
  input: dynamic.Dynamic,
) -> Result(Calculator, List(dynamic.DecodeError)) {
  input
  |> dynamic.decode3(
    Calculator,
    dynamic.field(named: "operation", of: fn(a) {
      use a <- result.try(dynamic.string(a))

      case a {
        "add" -> Ok(Add)
        "subtract" -> Ok(Subtract)
        "multiply" -> Ok(Multiply)
        "divide" -> Ok(Divide)
        _ ->
          Error([
            dynamic.DecodeError(
              "one of add, subtract, multiple, and divide",
              a,
              [],
            ),
          ])
      }
    }),
    dynamic.field(
      named: "a",
      of: dynamic.any([
        dynamic.float,
        fn(x) { x |> dynamic.int |> result.map(int.to_float) },
      ]),
    ),
    dynamic.field(
      named: "b",
      of: dynamic.any([
        dynamic.float,
        fn(x) { x |> dynamic.int |> result.map(int.to_float) },
      ]),
    ),
  )
}
