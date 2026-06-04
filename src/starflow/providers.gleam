/// Represents a supported LLM provider together with the configuration that
/// provider needs to be reached. Each variant carries exactly its own
/// requirements, so unusable combinations (such as an API key for a keyless
/// local server) cannot be represented.
///
/// ## Variants
/// - `Anthropic`: Claude's hosted API, authenticated with an API key
/// - `Ollama`: a local (or self-hosted) Ollama server, reached over its
///   OpenAI-compatible API at the given host
///
/// ## Examples
///
/// ```gleam
/// let model = model.new(providers.anthropic("sk-ant-..."))
/// let model = model.new(providers.ollama())
/// let model = model.new(providers.ollama_at("http://gpu-box:11434"))
/// ```
///
pub type Provider {
  Anthropic(api_key: String)
  Ollama(host: String)
}

const default_ollama_host = "http://localhost:11434"

/// Creates an Anthropic provider from a Claude API key.
pub fn anthropic(api_key: String) -> Provider {
  Anthropic(api_key:)
}

/// Creates an Ollama provider pointing at the default local host
/// (`http://localhost:11434`).
pub fn ollama() -> Provider {
  Ollama(default_ollama_host)
}

/// Creates an Ollama provider pointing at a custom host.
pub fn ollama_at(host: String) -> Provider {
  Ollama(host:)
}
