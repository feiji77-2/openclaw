import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { resolveImplicitProviders } from "./models-config.providers.js";

describe("MiniMax implicit provider (#15275)", () => {
  it("should use openai-completions API for API-key provider", async () => {
    const agentDir = mkdtempSync(join(tmpdir(), "openclaw-test-"));
    const previous = process.env.MINIMAX_API_KEY;
    process.env.MINIMAX_API_KEY = "test-key";

    try {
      const providers = await resolveImplicitProviders({ agentDir });
      expect(providers?.minimax).toBeDefined();
      expect(providers?.minimax?.api).toBe("openai-completions");
      expect(providers?.minimax?.baseUrl).toBe("https://api.minimax.chat/v1");
    } finally {
      if (previous === undefined) {
        delete process.env.MINIMAX_API_KEY;
      } else {
        process.env.MINIMAX_API_KEY = previous;
      }
    }
  });
});
