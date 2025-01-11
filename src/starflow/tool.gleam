import gleam/dict
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/result

import starflow/schema

/// Represents a tool that can be used by the model.
/// The type parameter `input` defines the expected input type,
/// while `output` defines the return type.
pub type Tool {
  Tool(
    name: String,
    description: String,
    schema: schema.Schema,
    output: schema.Schema,
    apply: fn(dynamic.Dynamic) -> Result(ToolResult, List(dynamic.DecodeError)),
  )
}

pub type ToolResult {
  String(String)
  Number(Float)
  Integer(Int)
  Boolean(Bool)
  Null

  Array(List(ToolResult))
  Object(List(#(String, ToolResult)))

  Enum(String)
}

pub fn result(tool_use: #(String, dynamic.Dynamic), tools: List(Tool)) {
  let #(name, tool_res) = tool_use

  let assert Ok(tool) =
    list.find(in: tools, one_that: fn(tool) { name == tool.name })

  let schema.Schema(json) = tool.output

  json
  |> json.to_string
  |> json.decode(using: decode_schema(_, tool_res))
}

fn decode_schema(
  schema_json: dynamic.Dynamic,
  from: dynamic.Dynamic,
) -> Result(ToolResult, List(dynamic.DecodeError)) {
  use object_type <- result.try(
    schema_json |> dynamic.field(named: "type", of: dynamic.string),
  )

  case object_type {
    "string" -> dynamic.string(from:) |> result.map(String)
    "number" -> dynamic.float(from:) |> result.map(Number)
    "integer" -> dynamic.int(from:) |> result.map(Integer)
    "boolean" -> dynamic.bool(from:) |> result.map(Boolean)
    "null" -> Ok(Null)
    "array" -> {
      use items_schema <- result.try(
        schema_json
        |> dynamic.field("items", Ok),
      )

      use items <- result.map(
        from |> dynamic.list(of: decode_schema(items_schema, _)),
      )

      Array(items)
    }
    "object" -> {
      use dict <- result.try(
        schema_json
        |> dynamic.field("properties", dynamic.dict(dynamic.string, Ok)),
      )

      use list <- result.map(
        {
          use #(key, value) <- list.map(dict |> dict.to_list)

          use dyn <- result.try(from |> dynamic.field(key, Ok))

          use value <- result.map(dyn |> decode_schema(value))

          #(key, value)
        }
        |> result.all,
      )

      Object(list)
    }
    _ ->
      Error([
        dynamic.DecodeError(
          expected: "valid schema type",
          found: object_type,
          path: [],
        ),
      ])
  }
}

/// Converts a tool definition to a JSON object matching the API specification
pub fn to_json(tool: Tool) -> json.Json {
  let schema.Schema(schema_json) = tool.schema
  json.object([
    #("name", json.string(tool.name)),
    #("description", json.string(tool.description)),
    #("input_schema", schema_json),
  ])
}
