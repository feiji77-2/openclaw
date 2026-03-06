import type { Api, Model } from "@mariozechner/pi-ai";

function isOpenAiCompletionsModel(model: Model<Api>): model is Model<"openai-completions"> {
  return model.api === "openai-completions";
}

/**
 * Ensures the model has an `input` field to prevent crashes in upstream SDK.
 * The SDK uses `model.input.includes("image")` without null checking.
 * @see https://github.com/jiulingyun/openclaw-cn/issues/32
 */
function ensureModelInput<T extends Model<Api>>(model: T): T {
  if (model.input && Array.isArray(model.input)) return model;
  return { ...model, input: ["text"] };
}

export function normalizeModelCompat(model: Model<Api>): Model<Api> {
  const safeModel = ensureModelInput(model);
  if (!isOpenAiCompletionsModel(safeModel)) return safeModel;

  const baseUrl = model.baseUrl ?? "";
  // Providers that don't support developer role (must use system role instead)
  const isZai = model.provider === "zai" || baseUrl.includes("api.z.ai");
  const isXiaomi = model.provider === "xiaomi" || baseUrl.includes("api.xiaomimimo.com");

  if (!isZai && !isXiaomi) return model;

  const openaiModel = safeModel as Model<"openai-completions">;
  const compat = openaiModel.compat ?? undefined;
  if (compat?.supportsDeveloperRole === false) return safeModel;

  openaiModel.compat = compat
    ? { ...compat, supportsDeveloperRole: false }
    : { supportsDeveloperRole: false };
  return openaiModel;
}
