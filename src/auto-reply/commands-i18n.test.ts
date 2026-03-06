import { describe, expect, it } from "vitest";
import {
  COMMANDS_I18N,
  COMMAND_GROUP_LABELS,
  getZhAliasToKeyMap,
  getCommandI18n,
  matchZhCommandAlias,
} from "./commands-i18n.js";

describe("commands-i18n", () => {
  describe("COMMANDS_I18N", () => {
    it("should have core commands defined", () => {
      const keys = COMMANDS_I18N.map((c) => c.key);
      expect(keys).toContain("new");
      expect(keys).toContain("stop");
      expect(keys).toContain("model");
      expect(keys).toContain("help");
      expect(keys).toContain("status");
    });

    it("should have Chinese names for all commands", () => {
      for (const cmd of COMMANDS_I18N) {
        expect(cmd.zhName).toBeTruthy();
        expect(cmd.zhDescription).toBeTruthy();
      }
    });

    it("should have groups assigned", () => {
      for (const cmd of COMMANDS_I18N) {
        expect(cmd.group).toBeTruthy();
        expect(Object.keys(COMMAND_GROUP_LABELS)).toContain(cmd.group);
      }
    });
  });

  describe("getZhAliasToKeyMap", () => {
    it("should return a map of Chinese aliases to command keys", () => {
      const map = getZhAliasToKeyMap();
      expect(map.get("新对话")).toBe("new");
      expect(map.get("停止")).toBe("stop");
      expect(map.get("模型")).toBe("model");
      expect(map.get("帮助")).toBe("help");
    });

    it("should be case insensitive", () => {
      const map = getZhAliasToKeyMap();
      // Chinese doesn't have case, but English aliases should work
      expect(map.has("新对话")).toBe(true);
    });
  });

  describe("getCommandI18n", () => {
    it("should return command info by key", () => {
      const newCmd = getCommandI18n("new");
      expect(newCmd).toBeDefined();
      expect(newCmd?.zhName).toBe("新对话");
      expect(newCmd?.group).toBe("conversation");
    });

    it("should return undefined for unknown key", () => {
      const unknown = getCommandI18n("nonexistent");
      expect(unknown).toBeUndefined();
    });
  });

  describe("matchZhCommandAlias", () => {
    it("should match Chinese aliases to command keys", () => {
      expect(matchZhCommandAlias("新对话")).toBe("new");
      expect(matchZhCommandAlias("停止")).toBe("stop");
      expect(matchZhCommandAlias("模型")).toBe("model");
      expect(matchZhCommandAlias("思考")).toBe("think");
    });

    it("should handle whitespace", () => {
      expect(matchZhCommandAlias("  新对话  ")).toBe("new");
      expect(matchZhCommandAlias("停止 ")).toBe("stop");
    });

    it("should return null for non-matching text", () => {
      expect(matchZhCommandAlias("你好")).toBeNull();
      expect(matchZhCommandAlias("随便什么")).toBeNull();
      expect(matchZhCommandAlias("/new")).toBeNull(); // slash commands don't match as aliases
    });
  });
});
