import type { ModelDefinitionConfig } from "../config/types.js";

const ZERO_COST = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };

// Full list of models known to be available through GitHub Copilot.
// Maintained here because the upstream pi-ai built-in list may lag behind.
// If a model isn't available for a given Copilot plan, the API will return an
// error at runtime; users can override via config.
const COPILOT_MODELS: ModelDefinitionConfig[] = [
  // --- Anthropic Claude ---
  {
    id: "claude-haiku-4.5",
    name: "Claude Haiku 4.5",
    api: "openai-completions",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 16_000,
  },
  {
    id: "claude-opus-4.5",
    name: "Claude Opus 4.5",
    api: "openai-completions",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 16_000,
  },
  {
    id: "claude-opus-4.6",
    name: "Claude Opus 4.6",
    api: "openai-completions",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 200_000,
    maxTokens: 16_000,
  },
  {
    id: "claude-sonnet-4",
    name: "Claude Sonnet 4",
    api: "openai-completions",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 16_000,
  },
  {
    id: "claude-sonnet-4.5",
    name: "Claude Sonnet 4.5",
    api: "openai-completions",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 16_000,
  },
  // --- Google Gemini ---
  {
    id: "gemini-2.5-pro",
    name: "Gemini 2.5 Pro",
    api: "openai-completions",
    reasoning: false,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 64_000,
  },
  {
    id: "gemini-3-flash-preview",
    name: "Gemini 3 Flash Preview",
    api: "openai-completions",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 64_000,
  },
  {
    id: "gemini-3-pro-preview",
    name: "Gemini 3 Pro Preview",
    api: "openai-completions",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 64_000,
  },
  // --- OpenAI GPT ---
  {
    id: "gpt-4.1",
    name: "GPT-4.1",
    api: "openai-completions",
    reasoning: false,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 16_384,
  },
  {
    id: "gpt-4o",
    name: "GPT-4o",
    api: "openai-completions",
    reasoning: false,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 64_000,
    maxTokens: 16_384,
  },
  {
    id: "gpt-5",
    name: "GPT-5",
    api: "openai-responses",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 128_000,
  },
  {
    id: "gpt-5-mini",
    name: "GPT-5 Mini",
    api: "openai-responses",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 64_000,
  },
  {
    id: "gpt-5.1",
    name: "GPT-5.1",
    api: "openai-responses",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 128_000,
  },
  {
    id: "gpt-5.1-codex",
    name: "GPT-5.1 Codex",
    api: "openai-responses",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 128_000,
  },
  {
    id: "gpt-5.1-codex-max",
    name: "GPT-5.1 Codex Max",
    api: "openai-responses",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 128_000,
  },
  {
    id: "gpt-5.1-codex-mini",
    name: "GPT-5.1 Codex Mini",
    api: "openai-responses",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 100_000,
  },
  {
    id: "gpt-5.2",
    name: "GPT-5.2",
    api: "openai-responses",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 64_000,
  },
  {
    id: "gpt-5.2-codex",
    name: "GPT-5.2 Codex",
    api: "openai-responses",
    reasoning: true,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 272_000,
    maxTokens: 128_000,
  },
  // --- xAI ---
  {
    id: "grok-code-fast-1",
    name: "Grok Code Fast 1",
    api: "openai-completions",
    reasoning: true,
    input: ["text"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 64_000,
  },
];

/** All model IDs known to be available through GitHub Copilot. */
export function getDefaultCopilotModelIds(): string[] {
  return COPILOT_MODELS.map((m) => m.id);
}

/** Full model definitions for GitHub Copilot (used when writing models.json). */
export function getCopilotModelDefinitions(): ModelDefinitionConfig[] {
  return COPILOT_MODELS;
}

export function buildCopilotModelDefinition(modelId: string): ModelDefinitionConfig {
  const id = modelId.trim();
  if (!id) throw new Error("Model id required");
  const existing = COPILOT_MODELS.find((m) => m.id === id);
  if (existing) return existing;
  // Fallback for unknown model IDs.
  return {
    id,
    name: id,
    api: "openai-completions",
    reasoning: false,
    input: ["text", "image"],
    cost: ZERO_COST,
    contextWindow: 128_000,
    maxTokens: 16_000,
  };
}
