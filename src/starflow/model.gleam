import starflow/api_key
import starflow/providers

/// Type alias for model names. Used by providers to identify specific model versions.
///
/// ## Examples
/// - `"claude-3-5-sonnet-20241022"` for Anthropic
///
pub type Name =
  String

/// Type alias for model names. Used by providers to identify specific model versions.
///
/// ## Examples
/// - `"claude-3-5-sonnet-20241022"` for Anthropic
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
/// - `provider`: The AI provider (e.g., Anthropic)
/// - `api_key`: Authentication key for the provider
/// - `name`: Specific model identifier
/// - `temperature`: Controls output randomness (0.0 - 1.0)
/// - `max_tokens`: Maximum tokens in model response
///
/// ## Examples
///
/// ```gleam
/// // Default Anthropic configuration
/// let model = new(anthropic_api_key)
///
/// // Custom configuration
/// let model = new(api_key)
///   |> with_name("claude-3-opus-20241022")
///   |> with_temperature(0.9)
/// ```
///
pub type Model {
  Model(
    provider: providers.Provider,
    api_key: api_key.APIKey,
    name: Name,
    temperature: Temperature,
    max_tokens: MaxTokens,
  )
}

/// Creates a new model configuration with provider-specific defaults.
///
/// Currently supported providers:
/// - Anthropic:
///   - Model: "claude-3-5-sonnet-20241022"
///   - Temperature: 0.7
///   - Max Tokens: 1024
///
/// ## Examples
///
/// ```gleam
/// let api_key = api_key.new(providers.Anthropic, "your-key-here")
/// let model = new(api_key)
/// ```
///
pub fn new(api_key: api_key.APIKey) -> Model {
  let provider = api_key.provider

  case provider {
    providers.Anthropic ->
      Model(provider, api_key, "claude-3-5-sonnet-20241022", 0.7, 1024)
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
