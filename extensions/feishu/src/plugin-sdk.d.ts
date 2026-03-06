/**
 * Type declarations for openclaw/plugin-sdk
 * 支持 TypeScript 类型检查，兼容上游 openclaw 和 openclaw-cn
 */

export interface ClawdbotPluginApi {
  registerChannel(id: string, plugin: any): void;
  registerTool(id: string, tool: any): void;
  registerHook(name: string, handler: any): void;
  registerHttpHandler(path: string, handler: any): void;
  registerCommand(name: string, handler: any): void;
}

export interface PluginRuntime {
  api: ClawdbotPluginApi;
  config: any;
}

export interface ChannelPlugin {
  id: string;
  name: string;
  description?: string;
  onboarding?: any;
  runtime?: any;
}

export interface ClawdbotConfig {
  channels?: Record<string, any>;
  providers?: Record<string, any>;
  [key: string]: any;
}

export interface ChannelConfigSchema {
  shape: Record<string, any>;
  parse: (data: unknown) => Promise<any>;
}

export function emptyPluginConfigSchema(): ChannelConfigSchema;

export function buildChannelConfigSchema(
  fields: Record<string, any>
): ChannelConfigSchema;

export function promptChannelAccessConfig(
  prompter: any,
  channel: string
): Promise<Record<string, any>>;

export type { ChannelConfigSchema, ChannelPlugin };
export type { PluginRuntime };
