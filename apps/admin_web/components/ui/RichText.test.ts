import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import { RichText } from "./RichText";

const render = (doc: unknown, props: Record<string, unknown> = {}) => renderToStaticMarkup(createElement(RichText, { doc, ...props }));
const p = (content: unknown[]) => ({ type: "paragraph", content });
const t = (text: string, marks?: unknown[]) => ({ type: "text", text, ...(marks ? { marks } : {}) });
const doc = (...content: unknown[]) => ({ type: "doc", content });

describe("RichText", () => {
  it("draws the whitelisted nodes and marks as elements", () => {
    const html = render(
      doc(
        { type: "heading", attrs: { level: 2 }, content: [t("Title")] },
        { type: "heading", attrs: { level: 3 }, content: [t("Sub")] },
        p([t("b", [{ type: "bold" }]), t("i", [{ type: "italic" }]), t("u", [{ type: "underline" }]), t("s", [{ type: "strike" }]), { type: "hardBreak" }, t("end")]),
        { type: "bulletList", content: [{ type: "listItem", content: [p([t("one")])] }] },
        { type: "orderedList", attrs: { start: 2 }, content: [{ type: "listItem", content: [p([t("two")])] }] },
        { type: "blockquote", content: [p([t("quote")])] },
      ),
    );
    expect(html).toContain(">Title</span></h3>");
    expect(html).toContain(">Sub</span></h4>");
    expect(html).toMatch(/<strong[^>]*>b<\/strong>/);
    expect(html).toContain("<em>i</em>");
    expect(html).toMatch(/<u[^>]*>u<\/u>/);
    expect(html).toContain("<s>s</s>");
    expect(html).toContain("<br/>");
    expect(html).toMatch(/<ul[^>]*><li[^>]*><p[^>]*><span>one<\/span><\/p><\/li><\/ul>/);
    expect(html).toMatch(/<ol start="2"[^>]*>/);
    expect(html).toMatch(/<blockquote[^>]*>/);
  });

  it("follows the page's heading level", () => {
    const html = render(doc({ type: "heading", attrs: { level: 2 }, content: [t("T")] }), { headingLevel: 2 });
    expect(html).toContain("</h2>");
  });

  it("writes text as text, never as HTML", () => {
    const html = render(doc(p([t('<img src=x onerror="alert(1)"><script>alert(1)</script>')])));
    expect(html).not.toContain("<script");
    expect(html).not.toContain("<img");
    expect(html).toContain("&lt;script&gt;");
  });

  it("drops unknown node and mark types", () => {
    const html = render(
      doc(
        { type: "html", content: [t("<b>raw</b>")] },
        { type: "image", attrs: { src: "https://x.example/a.png" } },
        p([t("kept", [{ type: "code" }, { type: "textStyle", attrs: { style: "color:red" } }])]),
      ),
    );
    expect(html).not.toContain("raw");
    expect(html).not.toContain("<img");
    expect(html).not.toContain("code");
    expect(html).not.toContain("style=");
    expect(html).toContain(">kept<");
  });

  it("opens an https link in a new tab, safely, and a portal path in place", () => {
    const html = render(
      doc(p([t("help", [{ type: "link", attrs: { href: "https://busin.example/help" } }]), t(" and "), t("subs", [{ type: "link", attrs: { href: "/subscriptions" } }])])),
      { newTabLabel: "opens in a new tab" },
    );
    expect(html).toMatch(/<a href="https:\/\/busin\.example\/help" target="_blank" rel="noopener noreferrer"[^>]*>/);
    expect(html).toContain("(opens in a new tab)");
    expect(html).toMatch(/<a [^>]*href="\/subscriptions"[^>]*>/);
    expect(html).not.toMatch(/href="\/subscriptions"[^>]*target="_blank"/);
  });

  it("refuses javascript:, // and other links, keeping their words", () => {
    for (const href of ["javascript:alert(1)", "//evil.example", "http://plain.example", "data:text/html,x", " /x"]) {
      const html = render(doc(p([t("words", [{ type: "link", attrs: { href } }])])));
      expect(html, href).not.toContain("<a");
      expect(html, href).not.toContain("href");
      expect(html, href).toContain("words");
    }
  });

  it("joins neighbouring words with the same link into one link", () => {
    const link = { type: "link", attrs: { href: "/stops" } };
    const html = render(doc(p([t("see ", [link]), t("stops", [link, { type: "bold" }])])));
    expect(html.match(/<a /g)?.length).toBe(1);
  });

  it("draws links as words in a preview", () => {
    const html = render(doc(p([t("help", [{ type: "link", attrs: { href: "https://busin.example" } }])])), { linkable: false });
    expect(html).not.toContain("<a");
    expect(html).toContain("help");
  });

  it("draws nothing for an empty or broken document", () => {
    expect(render(null)).toBe("");
    expect(render("<p>hi</p>")).toBe("");
    expect(render(doc())).toBe("");
  });
});
