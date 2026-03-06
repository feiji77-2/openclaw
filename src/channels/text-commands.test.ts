import { describe, expect, it } from "vitest";
import {
  parseTextCommand,
  isHelpTrigger,
  toSlashCommand,
  getHelpMenuText,
} from "./text-commands.js";

describe("text-commands", () => {
  describe("isHelpTrigger", () => {
    it("should detect Chinese help triggers", () => {
      expect(isHelpTrigger("菜单")).toBe(true);
      expect(isHelpTrigger("命令")).toBe(true);
      expect(isHelpTrigger("帮助")).toBe(true);
      expect(isHelpTrigger("命令列表")).toBe(true);
      expect(isHelpTrigger("怎么用")).toBe(true);
      expect(isHelpTrigger("使用帮助")).toBe(true);
    });

    it("should detect English help triggers", () => {
      expect(isHelpTrigger("menu")).toBe(true);
      expect(isHelpTrigger("help")).toBe(true);
      expect(isHelpTrigger("commands")).toBe(true);
    });

    it("should detect punctuation triggers", () => {
      expect(isHelpTrigger("?")).toBe(true);
      expect(isHelpTrigger("？")).toBe(true);
    });

    it("should handle whitespace", () => {
      expect(isHelpTrigger("  菜单  ")).toBe(true);
      expect(isHelpTrigger("  help  ")).toBe(true);
    });

    it("should not match non-help text", () => {
      expect(isHelpTrigger("你好")).toBe(false);
      expect(isHelpTrigger("hello")).toBe(false);
      expect(isHelpTrigger("/new")).toBe(false);
    });
  });

  describe("parseTextCommand", () => {
    it("should parse help triggers", () => {
      expect(parseTextCommand("菜单")).toEqual({ type: "help" });
      expect(parseTextCommand("命令")).toEqual({ type: "help" });
      expect(parseTextCommand("help")).toEqual({ type: "help" });
      expect(parseTextCommand("?")).toEqual({ type: "help" });
    });

    it("should parse slash commands without args", () => {
      expect(parseTextCommand("/new")).toEqual({ type: "command", key: "new" });
      expect(parseTextCommand("/stop")).toEqual({ type: "command", key: "stop" });
      expect(parseTextCommand("/model")).toEqual({ type: "command", key: "model" });
    });

    it("should parse slash commands with args", () => {
      expect(parseTextCommand("/model claude-opus")).toEqual({
        type: "command",
        key: "model",
        args: "claude-opus",
      });
      expect(parseTextCommand("/think high")).toEqual({
        type: "command",
        key: "think",
        args: "high",
      });
    });

    it("should parse Chinese command aliases without args", () => {
      expect(parseTextCommand("/新对话")).toEqual({ type: "command", key: "new" });
      expect(parseTextCommand("/停止")).toEqual({ type: "command", key: "stop" });
      expect(parseTextCommand("/模型")).toEqual({ type: "command", key: "model" });
      expect(parseTextCommand("/状态")).toEqual({ type: "command", key: "status" });
    });

    it("should parse Chinese command aliases with args", () => {
      expect(parseTextCommand("/模型 claude-opus")).toEqual({
        type: "command",
        key: "model",
        args: "claude-opus",
      });
      expect(parseTextCommand("/思考 high")).toEqual({
        type: "command",
        key: "think",
        args: "high",
      });
    });

    it("should return none for regular text", () => {
      expect(parseTextCommand("你好")).toEqual({ type: "none" });
      expect(parseTextCommand("hello world")).toEqual({ type: "none" });
      expect(parseTextCommand("这是一段普通消息")).toEqual({ type: "none" });
    });

    it("should return none for Chinese commands without slash", () => {
      expect(parseTextCommand("新对话")).toEqual({ type: "none" });
      expect(parseTextCommand("停止")).toEqual({ type: "none" });
      expect(parseTextCommand("模型")).toEqual({ type: "none" });
    });

    it("should handle edge cases", () => {
      expect(parseTextCommand("")).toEqual({ type: "none" });
      expect(parseTextCommand("  ")).toEqual({ type: "none" });
      expect(parseTextCommand("/")).toEqual({ type: "command", key: "" });
    });
  });

  describe("toSlashCommand", () => {
    it("should convert command results to slash format", () => {
      expect(toSlashCommand({ type: "command", key: "new" })).toBe("/new");
      expect(toSlashCommand({ type: "command", key: "model", args: "claude" })).toBe(
        "/model claude",
      );
    });

    it("should convert help to /commands", () => {
      expect(toSlashCommand({ type: "help" })).toBe("/commands");
    });

    it("should return null for none type", () => {
      expect(toSlashCommand({ type: "none" })).toBeNull();
    });
  });

  describe("getHelpMenuText", () => {
    it("should generate formatted help text", () => {
      const helpText = getHelpMenuText();
      expect(helpText).toContain("可用命令列表");
      expect(helpText).toContain("对话控制");
      expect(helpText).toContain("模型设置");
      expect(helpText).toContain("新对话");
      expect(helpText).toContain("/new");
    });

    it("should include all command groups", () => {
      const helpText = getHelpMenuText();
      expect(helpText).toContain("💬 对话控制");
      expect(helpText).toContain("🤖 模型设置");
      expect(helpText).toContain("ℹ️ 信息查询");
      expect(helpText).toContain("📝 会话管理");
      expect(helpText).toContain("⚙️ 高级功能");
    });
  });
});
