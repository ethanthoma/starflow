import gleam/json
import gleam/option

import gleeunit/should

import starflow/model
import starflow/providers
import starflow/providers/anthropic
import starflow/state
import starflow/tool
import tools/calculator

pub fn encode_text_test() {
  let model = model.new(providers.anthropic("k"))
  let messages = [state.Message("user", [state.TextContent("hi")])]

  anthropic.encode(model, messages, [])
  |> json.to_string
  |> should.equal(
    "{\"model\":\"claude-3-5-sonnet-20241022\",\"max_tokens\":1024,\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"hi\"}]}],\"tools\":[]}",
  )
}

pub fn decode_text_response_test() {
  let body =
    "{\"id\":\"msg_1\",\"content\":[{\"type\":\"text\",\"text\":\"hi\"}],\"model\":\"claude-3-5-sonnet-20241022\",\"stop_reason\":\"end_turn\",\"usage\":{\"input_tokens\":10,\"output_tokens\":5}}"

  let resp = json.parse(body, anthropic.response()) |> should.be_ok

  resp.id |> should.equal("msg_1")
  resp.content |> should.equal([state.TextContent("hi")])
  resp.stop_reason |> should.equal(option.Some(state.EndTurn))
  resp.usage.output_tokens |> should.equal(5)
}

pub fn decode_tool_use_response_test() {
  let body =
    "{\"id\":\"msg_2\",\"content\":[{\"type\":\"tool_use\",\"id\":\"t1\",\"name\":\"calculator\",\"input\":{\"operation\":\"add\",\"a\":1,\"b\":2}}],\"model\":\"claude-3-5-sonnet-20241022\",\"stop_reason\":\"tool_use\",\"usage\":{\"input_tokens\":10,\"output_tokens\":5}}"

  let resp = json.parse(body, anthropic.response()) |> should.be_ok

  resp.stop_reason |> should.equal(option.Some(state.ToolUse))

  let assert [state.ToolContent(_id, name, input)] = resp.content
  name |> should.equal("calculator")
  calculator.tool().apply(input) |> should.equal(Ok(tool.Number(3.0)))
}
