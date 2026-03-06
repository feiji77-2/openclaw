import type { ClawdbotPluginApi } from "openclaw/plugin-sdk";
declare const plugin: {
    id: string;
    name: string;
    description: string;
    configSchema: {
        safeParse?: (value: unknown) => {
            success: boolean;
            data?: unknown;
            error?: {
                issues?: Array<{
                    path: Array<string | number>;
                    message: string;
                }>;
            };
        };
        parse?: (value: unknown) => unknown;
        validate?: (value: unknown) => {
            ok: true;
            value?: unknown;
        } | {
            ok: false;
            errors: string[];
        };
        uiHints?: Record<string, {
            label?: string;
            help?: string;
            advanced?: boolean;
            sensitive?: boolean;
            placeholder?: string;
        }>;
        jsonSchema?: Record<string, unknown>;
    };
    register(api: ClawdbotPluginApi): void;
};
export default plugin;
//# sourceMappingURL=index.d.ts.map