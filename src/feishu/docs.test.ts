import { describe, it, expect } from "vitest";
import { extractDocRefsFromText, extractDocRefsFromPost } from "./docs.js";

describe("extractDocRefsFromText", () => {
  it("should extract docx URL", () => {
    const text = "请查看这个文档 https://example.feishu.cn/docx/B4EPdAYx8oi8HRxgPQQb";
    const refs = extractDocRefsFromText(text);
    expect(refs).toHaveLength(1);
    expect(refs[0].docToken).toBe("B4EPdAYx8oi8HRxgPQQb");
    expect(refs[0].docType).toBe("docx");
  });

  it("should extract wiki URL", () => {
    const text = "知识库链接: https://company.feishu.cn/wiki/WikiTokenExample123";
    const refs = extractDocRefsFromText(text);
    expect(refs).toHaveLength(1);
    expect(refs[0].docType).toBe("wiki");
    expect(refs[0].docToken).toBe("WikiTokenExample123");
  });

  it("should extract sheet URL", () => {
    const text = "表格地址 https://open.larksuite.com/sheets/SheetToken1234567890";
    const refs = extractDocRefsFromText(text);
    expect(refs).toHaveLength(1);
    expect(refs[0].docType).toBe("sheet");
  });

  it("should extract bitable/base URL", () => {
    const text = "多维表格 https://abc.feishu.cn/base/BitableToken1234567890";
    const refs = extractDocRefsFromText(text);
    expect(refs).toHaveLength(1);
    expect(refs[0].docType).toBe("bitable");
  });

  it("should extract multiple URLs", () => {
    const text = `
      文档1: https://example.feishu.cn/docx/Doc1Token12345678901
      文档2: https://example.feishu.cn/wiki/Wiki1Token12345678901
    `;
    const refs = extractDocRefsFromText(text);
    expect(refs).toHaveLength(2);
  });

  it("should deduplicate same token", () => {
    const text = `
      https://example.feishu.cn/docx/SameToken123456789012
      https://example.feishu.cn/docx/SameToken123456789012
    `;
    const refs = extractDocRefsFromText(text);
    expect(refs).toHaveLength(1);
  });

  it("should return empty array for text without URLs", () => {
    const text = "这是一段普通文本，没有文档链接";
    const refs = extractDocRefsFromText(text);
    expect(refs).toHaveLength(0);
  });
});

describe("extractDocRefsFromPost", () => {
  it("should extract URL from link element", () => {
    const content = {
      title: "测试富文本",
      content: [
        [
          {
            tag: "a",
            text: "API文档",
            href: "https://example.feishu.cn/docx/ApiDocToken123456789",
          },
        ],
      ],
    };
    const refs = extractDocRefsFromPost(content);
    expect(refs).toHaveLength(1);
    expect(refs[0].title).toBe("API文档");
    expect(refs[0].docToken).toBe("ApiDocToken123456789");
  });

  it("should extract URL from title", () => {
    const content = {
      title: "查看 https://example.feishu.cn/docx/TitleDocToken1234567",
      content: [],
    };
    const refs = extractDocRefsFromPost(content);
    expect(refs).toHaveLength(1);
  });

  it("should extract URL from text element", () => {
    const content = {
      content: [
        [
          {
            tag: "text",
            text: "请访问 https://example.feishu.cn/wiki/TextWikiToken12345678",
          },
        ],
      ],
    };
    const refs = extractDocRefsFromPost(content);
    expect(refs).toHaveLength(1);
    expect(refs[0].docType).toBe("wiki");
  });

  it("should handle stringified JSON", () => {
    const content = JSON.stringify({
      title: "文档分享",
      content: [
        [
          {
            tag: "a",
            text: "点击查看",
            href: "https://example.feishu.cn/docx/JsonDocToken123456789",
          },
        ],
      ],
    });
    const refs = extractDocRefsFromPost(content);
    expect(refs).toHaveLength(1);
  });

  it("should return empty array for post without doc links", () => {
    const content = {
      title: "普通标题",
      content: [
        [
          { tag: "text", text: "普通文本" },
          { tag: "a", text: "普通链接", href: "https://example.com" },
        ],
      ],
    };
    const refs = extractDocRefsFromPost(content);
    expect(refs).toHaveLength(0);
  });
});
