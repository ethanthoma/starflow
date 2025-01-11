import gleam/json
import gleam/list

/// Represents a JSON Schema type
pub type Schema {
  Schema(json: json.Json)
}

/// Creates a string type schema
pub fn string() -> Schema {
  Schema(json.object([#("type", json.string("string"))]))
}

/// Creates a string type schema with format
pub fn string_with_format(format: String) -> Schema {
  Schema(
    json.object([
      #("type", json.string("string")),
      #("format", json.string(format)),
    ]),
  )
}

/// Creates a number type schema
pub fn number() -> Schema {
  Schema(json.object([#("type", json.string("number"))]))
}

/// Creates an integer type schema
pub fn integer() -> Schema {
  Schema(json.object([#("type", json.string("integer"))]))
}

/// Creates a boolean type schema
pub fn boolean() -> Schema {
  Schema(json.object([#("type", json.string("boolean"))]))
}

/// Creates an array type schema
pub fn array(items: Schema) -> Schema {
  let Schema(items_json) = items
  Schema(json.object([#("type", json.string("array")), #("items", items_json)]))
}

/// Creates an object type schema
pub fn object(properties: List(Property)) -> Schema {
  let #(props_json, required) =
    properties
    |> list.fold(#([], []), fn(acc, prop) {
      let #(props, reqs) = acc
      let Property(name, Schema(schema), required) = prop
      case required {
        True -> #([#(name, schema), ..props], [json.string(name), ..reqs])
        False -> #([#(name, schema), ..props], reqs)
      }
    })

  Schema(
    json.object([
      #("type", json.string("object")),
      #("properties", json.object(props_json)),
      #("required", json.array(required, fn(x) { x })),
    ]),
  )
}

/// Creates an enum type schema
pub fn enum(values: List(String)) -> Schema {
  Schema(json.object([#("enum", json.array(values, json.string))]))
}

/// Represents an object property
pub type Property {
  Property(name: String, schema: Schema, required: Bool)
}

/// Creates a required property
pub fn required(name: String, schema: Schema) -> Property {
  Property(name, schema, True)
}

/// Creates an optional property
pub fn optional(name: String, schema: Schema) -> Property {
  Property(name, schema, False)
}
