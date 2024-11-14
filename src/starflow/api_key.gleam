import starflow/providers

/// Represents an API key associated with a specific provider.
/// This type ensures that API keys are always paired with their corresponding provider,
/// preventing misuse of keys across different services.
///
/// ## Fields
/// - `provider`: The provider this API key is for (e.g., Anthropic)
/// - `String`: The actual API key value
///
/// ## Examples
///
/// ```gleam
/// // Create an Anthropic API key
/// let key = new(providers.Anthropic, "sk-ant-123...")
///
/// // Pattern match if needed
/// case key {
///   APIKey(providers.Anthropic, value) -> // Handle Anthropic key
///   APIKey(other_provider, _) -> // Handle other provider
/// }
/// ```
///
pub type APIKey {
  APIKey(provider: providers.Provider, String)
}

/// Creates a new APIKey with the specified provider and key value.
///
/// ## Arguments
/// - `provider`: The provider this key is associated with
/// - `key`: The API key string
///
/// ## Examples
///
/// ```gleam
/// // Using environment variable
/// use key <- result.try(
///   envoy.get("ANTHROPIC_API_KEY")
///   |> result.map(new(providers.Anthropic, _))
/// )
///
/// // Direct initialization
/// let key = new(providers.Anthropic, "sk-ant-123...")
/// ```
///
pub fn new(provider: providers.Provider, key: String) -> APIKey {
  APIKey(provider, key)
}

/// Retrieves the raw API key string from an APIKey.
/// This is typically used when making API requests where the raw key
/// is needed for authentication.
///
/// ## Examples
///
/// ```gleam
/// let key = new(providers.Anthropic, "sk-ant-123...")
/// let raw_key = get(key)  // Returns "sk-ant-123..."
///
/// // Common usage in request headers
/// request.set_header("x-api-key", get(key))
/// ```
///
pub fn get(api_key: APIKey) -> String {
  let APIKey(_, key) = api_key
  key
}
