/**
 * 命令帮助文本生成
 *
 * 生成格式化的命令列表和帮助信息，用于：
 * 1. 响应 "菜单"、"命令" 等触发词
 * 2. 显示分组的命令列表
 */

import {
  COMMANDS_I18N,
  COMMAND_GROUP_LABELS,
  type CommandGroup,
  type CommandI18n,
} from "./commands-i18n.js";

export type HelpTextOptions = {
  /** 是否包含命令分组标题 */
  showGroups?: boolean;
  /** 是否显示英文命令名 */
  showEnglishName?: boolean;
  /** 要包含的分组（默认全部） */
  groups?: CommandGroup[];
  /** 命令前缀 (默认 "/") */
  commandPrefix?: string;
};

/**
 * 生成格式化的命令帮助文本
 */
export function generateCommandHelpText(options: HelpTextOptions = {}): string {
  const { showGroups = true, showEnglishName = true, groups, commandPrefix = "/" } = options;

  const filteredCommands = groups
    ? COMMANDS_I18N.filter((cmd) => cmd.group && groups.includes(cmd.group))
    : COMMANDS_I18N;

  if (!showGroups) {
    return formatCommandList(filteredCommands, {
      showEnglishName,
      commandPrefix,
    });
  }

  // 按分组组织命令
  const groupedCommands = new Map<CommandGroup, CommandI18n[]>();

  // 初始化分组顺序
  const groupOrder: CommandGroup[] = [
    "conversation",
    "model",
    "info",
    "session",
    "advanced",
    "other",
  ];

  for (const group of groupOrder) {
    groupedCommands.set(group, []);
  }

  for (const cmd of filteredCommands) {
    const group = cmd.group ?? "other";
    const list = groupedCommands.get(group);
    if (list) {
      list.push(cmd);
    }
  }

  const sections: string[] = [];

  for (const group of groupOrder) {
    const commands = groupedCommands.get(group);
    if (!commands || commands.length === 0) continue;

    const groupLabel = COMMAND_GROUP_LABELS[group];
    const commandLines = formatCommandList(commands, {
      showEnglishName,
      commandPrefix,
      indent: "  ",
    });

    sections.push(`${groupLabel}\n${commandLines}`);
  }

  const header = "📋 可用命令列表\n";
  const footer = '\n💡 输入 "/命令名" 即可使用（如 /新对话、/模型）';

  return header + "\n" + sections.join("\n\n") + footer;
}

function formatCommandList(
  commands: CommandI18n[],
  options: {
    showEnglishName?: boolean;
    commandPrefix?: string;
    indent?: string;
  },
): string {
  const { showEnglishName = true, commandPrefix = "/", indent = "" } = options;

  return commands
    .map((cmd) => {
      const englishPart = showEnglishName ? ` (${commandPrefix}${cmd.key})` : "";
      return `${indent}• ${cmd.zhName}${englishPart} - ${cmd.zhDescription}`;
    })
    .join("\n");
}

/**
 * 生成简短的命令提示（用于欢迎消息等）
 */
export function generateCommandHint(): string {
  return '💡 输入 "菜单" 或 "命令" 查看所有可用命令';
}

/**
 * 生成特定分组的命令列表
 */
export function generateGroupHelpText(group: CommandGroup): string {
  const groupLabel = COMMAND_GROUP_LABELS[group];
  const commands = COMMANDS_I18N.filter((cmd) => cmd.group === group);

  if (commands.length === 0) {
    return `${groupLabel}\n  暂无命令`;
  }

  const commandLines = formatCommandList(commands, {
    showEnglishName: true,
    commandPrefix: "/",
    indent: "  ",
  });

  return `${groupLabel}\n${commandLines}`;
}
