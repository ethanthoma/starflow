/// Represents supported AI service providers.
///
/// ## Variants
/// - `Anthropic`: Provider for Claude and other Anthropic models
///
/// ## Examples
///
/// ```gleam
/// let provider = Anthropic
/// let model = model.new(provider, api_key, "claude-3-sonnet-20240229")
/// ```
///
pub type Provider {
  Anthropic
}

/// Returns the base URL for the API of the specified provider.
///
/// ## Examples
///
/// ```gleam
/// url(Anthropic)  // Returns "https://api.anthropic.com/v1"
/// ```
///
/// ## Provider URLs
/// - Anthropic: https://api.anthropic.com/v1
///
pub fn url(provider: Provider) -> String {
  case provider {
    Anthropic -> "https://api.anthropic.com/v1"
  }
}

/// Returns the API version string required by the specified provider.
///
/// This version identifier is used in API request headers to ensure
/// compatibility with the provider's API.
///
/// ## Examples
///
/// ```gleam
/// version(Anthropic)  // Returns "2023-06-01"
/// ```
///
/// ## Provider Versions
/// - Anthropic: 2023-06-01 (Claude API version)
///
pub fn version(provider: Provider) -> String {
  case provider {
    Anthropic -> "2023-06-01"
  }
}
