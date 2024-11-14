import gleam/dynamic
import gleam/json

import starflow/model
import starflow/state

pub fn encode(model: model.Model, messages: List(state.Message)) {
  json.object([
    #("model", json.string(model.name)),
    #("max_tokens", json.int(model.max_tokens)),
    #("messages", json.array(messages, message)),
  ])
}

fn message(message: state.Message) {
  json.object([
    #("role", json.string(message.role)),
    #("content", json.array(message.content, content)),
  ])
}

fn content(content: state.Content) -> json.Json {
  case content {
    state.TextContent(text) ->
      json.object([#("type", json.string("text")), #("text", json.string(text))])
    state.ImageContent(source) ->
      json.object([
        #("type", json.string("image")),
        #("source", image_source(source)),
      ])
    state.ToolContent(id, name, input) -> {
      let assert Ok(input) = dynamic.string(input)

      json.object([
        #("type", json.string("tool_use")),
        #("id", json.string(id)),
        #("name", json.string(name)),
        #("input", json.string(input)),
      ])
    }
  }
}

fn image_source(source: state.ImageSource) -> json.Json {
  case source {
    state.Base64Image(data, media_type) ->
      json.object([
        #("type", json.string("base64")),
        #("data", json.string(data)),
        #("media_type", json.string(media_type)),
      ])
  }
}
