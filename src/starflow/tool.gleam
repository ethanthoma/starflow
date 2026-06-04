import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list

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
    apply: fn(dynamic.Dynamic) -> Result(ToolResult, List(decode.DecodeError)),
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

pub fn result(
  tool_use: #(String, dynamic.Dynamic),
  tools: List(Tool),
) -> Result(ToolResult, List(decode.DecodeError)) {
  let #(name, tool_res) = tool_use

  let assert Ok(tool) =
    list.find(in: tools, one_that: fn(tool) { name == tool.name })

  let schema.Schema(json) = tool.output

  case json.parse(json.to_string(json), decode.dynamic) {
    Ok(schema_json) -> decode.run(tool_res, schema_decoder(schema_json))
    Error(_) -> Error([decode.DecodeError("schema", "invalid", [])])
  }
}

fn schema_decoder(schema_json: dynamic.Dynamic) -> decode.Decoder(ToolResult) {
  case decode.run(schema_json, decode.at(["type"], decode.string)) {
    Ok("string") -> decode.string |> decode.map(String)
    Ok("number") -> decode.float |> decode.map(Number)
    Ok("integer") -> decode.int |> decode.map(Integer)
    Ok("boolean") -> decode.bool |> decode.map(Boolean)
    Ok("null") -> decode.success(Null)
    Ok("array") ->
      case decode.run(schema_json, decode.at(["items"], decode.dynamic)) {
        Ok(items) -> decode.list(schema_decoder(items)) |> decode.map(Array)
        Error(_) -> decode.failure(Null, "array schema with items")
      }
    Ok("object") ->
      case
        decode.run(
          schema_json,
          decode.at(["properties"], decode.dict(decode.string, decode.dynamic)),
        )
      {
        Ok(properties) ->
          properties
          |> dict.to_list
          |> list.fold(decode.success([]), fn(acc, kv) {
            let #(key, value_schema) = kv
            use pairs <- decode.then(acc)
            use value <- decode.field(key, schema_decoder(value_schema))
            decode.success([#(key, value), ..pairs])
          })
          |> decode.map(fn(pairs) { Object(list.reverse(pairs)) })
        Error(_) -> decode.failure(Null, "object schema with properties")
      }
    _ -> decode.failure(Null, "valid schema type")
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
