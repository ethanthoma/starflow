import gleam/json
import gleam/option

import gleeunit/should

import starflow/model
import starflow/providers
import starflow/providers/ollama
import starflow/state
import starflow/tool
import tools/calculator

pub fn endpoint_test() {
  ollama.endpoint("http://localhost:11434")
  |> should.equal("http://localhost:11434/v1/chat/completions")
}

pub fn encode_text_test() {
  let model = model.new(providers.ollama()) |> model.with_name("llama3.2")
  let messages = [state.Message("user", [state.TextContent("hi")])]

  ollama.encode(model, messages, [])
  |> json.to_string
  |> should.equal(
    "{\"model\":\"llama3.2\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":1024,\"temperature\":0.7}",
  )
}

pub fn decode_text_response_test() {
  let body =
    "{\"id\":\"chatcmpl-1\",\"model\":\"llama3.2\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"42 * 17 = 714\"},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":26,\"completion_tokens\":7}}"

  let resp = json.parse(body, ollama.response()) |> should.be_ok

  resp.content |> should.equal([state.TextContent("42 * 17 = 714")])
  resp.stop_reason |> should.equal(option.Some(state.EndTurn))
  resp.usage.input_tokens |> should.equal(26)
  resp.usage.output_tokens |> should.equal(7)
}

// content arrives null and arguments is a JSON-encoded string
// the decoded ToolContent.input must be the structured object so tool.apply works
pub fn decode_tool_call_response_test() {
  let body =
    "{\"id\":\"chatcmpl-2\",\"model\":\"llama3.2\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":null,\"tool_calls\":[{\"id\":\"call_1\",\"type\":\"function\",\"function\":{\"name\":\"calculator\",\"arguments\":\"{\\\"operation\\\":\\\"multiply\\\",\\\"a\\\":42,\\\"b\\\":17}\"}}]},\"finish_reason\":\"tool_calls\"}],\"usage\":{\"prompt_tokens\":50,\"completion_tokens\":20}}"

  let resp = json.parse(body, ollama.response()) |> should.be_ok

  resp.stop_reason |> should.equal(option.Some(state.ToolUse))

  let assert [state.ToolContent(id, name, input)] = resp.content
  id |> should.equal("call_1")
  name |> should.equal("calculator")
  calculator.tool().apply(input) |> should.equal(Ok(tool.Number(714.0)))
}
