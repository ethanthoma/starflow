import starflow/providers

/// Type alias for model names. Used by providers to identify specific model versions.
///
/// ## Examples
/// - `"claude-3-5-sonnet-20241022"` for Anthropic
///
pub type Name =
  String

/// Type alias for model temperature setting. Controls randomness in model outputs.
///
/// ## Range
/// - 0.0: Most deterministic, best for analytical tasks
/// - 1.0: Most random, best for creative tasks
/// - Typical values: 0.0 - 1.0
///
pub type Temperature =
  Float

/// Type alias for maximum tokens allowed in model response.
///
/// ## Notes
/// - Higher values allow for longer responses but use more tokens
/// - Provider-specific limits apply
/// - Consider cost implications when setting this value
///
pub type MaxTokens =
  Int

/// Configuration for a language model, including provider details and generation parameters.
///
/// ## Fields
/// - `provider`: The provider and its connection config (e.g., Anthropic or Ollama)
/// - `name`: Specific model identifier
/// - `temperature`: Controls output randomness (0.0 - 1.0)
/// - `max_tokens`: Maximum tokens in model response
///
/// ## Examples
///
/// ```gleam
/// // Default Anthropic configuration
/// let model = new(providers.anthropic("your-key-here"))
///
/// // Swap to a local Ollama server (one line)
/// let model = new(providers.ollama())
///
/// // Custom configuration
/// let model =
///   new(providers.anthropic("your-key-here"))
///   |> with_name("claude-3-opus-20241022")
/// ```
///
pub type Model {
  Model(
    provider: providers.Provider,
    name: Name,
    temperature: Temperature,
    max_tokens: MaxTokens,
  )
}

/// Creates a new model configuration with provider-specific defaults.
///
/// Defaults per provider:
/// - Anthropic: `"claude-3-5-sonnet-20241022"`, temperature 0.7, max tokens 1024
/// - Ollama: `"llama3.2"`, temperature 0.7, max tokens 1024
///
/// ## Examples
///
/// ```gleam
/// let model = new(providers.anthropic("your-key-here"))
/// let model = new(providers.ollama())
/// ```
///
pub fn new(provider: providers.Provider) -> Model {
  case provider {
    providers.Anthropic(..) ->
      Model(provider, "claude-3-5-sonnet-20241022", 0.7, 1024)
    providers.Ollama(..) -> Model(provider, "llama3.2", 0.7, 1024)
  }
}

/// Updates the model name while preserving other settings.
///
/// ## Examples
///
/// ```gleam
/// // Switch to a different Claude model
/// let model = new(api_key)
///   |> with_name("claude-3-opus-20241022")
///
/// // Use a specific model version
/// let model = new(api_key)
///   |> with_name("claude-3-5-sonnet-20240229")
/// ```
///
/// ## Notes
/// - Ensure the model name is valid for the provider
/// - Different models may have different capabilities and costs
///
pub fn with_name(model: Model, name: String) -> Model {
  Model(..model, name: name)
}
