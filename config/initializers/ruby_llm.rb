RubyLLM.configure do |config|
  config.openai_api_key = ENV["GITHUB_TOKEN"]
  config.openai_api_base = "https://models.inference.ai.azure.com"
  config.default_model = "gpt-4o"
  config.default_params = { max_tokens: 2048 }
end
