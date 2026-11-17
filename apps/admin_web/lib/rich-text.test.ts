import { describe, expect, it } from "vitest";

import { cleanDoc, docToPlainText, isSafeHref, MAX_DEPTH, MAX_DOC_BYTES, MAX_TEXT, parseNoticeDoc, textToDoc, type RichDoc } from "./rich-text";

const p = (text: string, marks?: unknown[]) => ({ type: "paragraph", content: [{ type: "text", text, ...(marks ? { marks } : {}) }] });
const doc = (...content: unknown[]) => ({ type: "doc", content });
const item = (text: string) => ({ type: "listItem", content: [p(text)] });

describe("isSafeHref", () => {
  it("takes https addresses and portal paths", () => {
    expect(isSafeHref("https://busin.example/help")).toBe(true);
    expect(isSafeHref("https://busin.example/a?b=c#d")).toBe(true);
    expect(isSafeHref("/subscriptions")).toBe(true);
    expect(isSafeHref("/people?role=verify")).toBe(true);
    expect(isSafeHref("/")).toBe(true);
  });

  it("refuses every other scheme, other hosts by //, and tricks", () => {
    for (const bad of [
      "javascript:alert(1)",
      "JavaScript:alert(1)",
      " javascript:alert(1)",
      "java\tscript:alert(1)",
      "data:text/html,<script>alert(1)</script>",
      "vbscript:msgbox",
      "http://busin.example",
      "mailto:a@b.c",
      "//evil.example",
      "/\\evil.example",
      "\\\\evil.example",
      "https://",
      "https:///path",
      "https://user:pass@busin.example",
      "https://busin.example/a b",
      "subscriptions",
      "",
      `https://busin.example/${"a".repeat(600)}`,
      42,
      null,
    ]) {
      expect(isSafeHref(bad), String(bad)).toBe(false);
    }
  });
});

describe("cleanDoc", () => {
  it("keeps the whitelisted nodes and marks, and only the attributes it uses", () => {
    const { doc: clean, problem } = cleanDoc(
      doc(
        { type: "heading", attrs: { level: 2, id: "x" }, content: [{ type: "text", text: "Title" }] },
        { type: "paragraph", attrs: { textAlign: "left" }, content: [{ type: "text", text: "Bold", marks: [{ type: "bold" }, { type: "italic" }] }, { type: "hardBreak" }] },
        { type: "orderedList", attrs: { start: 3, type: null }, content: [item("a")] },
        { type: "blockquote", content: [p("q")] },
        p("link", [{ type: "link", attrs: { href: "https://x.example", target: "_blank", class: "evil", rel: "opener" } }]),
      ),
    );
    expect(problem).toBeNull();
    expect(clean).toEqual(
      doc(
        { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "Title" }] },
        { type: "paragraph", content: [{ type: "text", text: "Bold", marks: [{ type: "bold" }, { type: "italic" }] }, { type: "hardBreak" }] },
        { type: "orderedList", attrs: { start: 3 }, content: [item("a")] },
        { type: "blockquote", content: [p("q")] },
        p("link", [{ type: "link", attrs: { href: "https://x.example" } }]),
      ),
    );
  });

  it("drops unknown nodes and marks and says so", () => {
    const html = cleanDoc(doc({ type: "html", content: "<script>alert(1)</script>" }, p("ok")));
    expect(html.doc).toEqual(doc(p("ok")));
    expect(html.problem).toBe("node");
    const code = cleanDoc(doc(p("x", [{ type: "code" }])));
    expect(code.doc).toEqual(doc(p("x")));
    expect(code.problem).toBe("mark");
    const image = cleanDoc(doc({ type: "paragraph", content: [{ type: "image", attrs: { src: "https://x" } }, { type: "text", text: "t" }] }));
    expect(image.doc).toEqual(doc(p("t")));
    expect(image.problem).toBe("node");
  });

  it("drops a bad link but keeps its words", () => {
    const { doc: clean, problem } = cleanDoc(doc(p("click", [{ type: "bold" }, { type: "link", attrs: { href: "javascript:alert(1)" } }])));
    expect(clean).toEqual(doc(p("click", [{ type: "bold" }])));
    expect(problem).toBe("link");
  });

  it("refuses what is not a document", () => {
    for (const bad of [null, "doc", [], { type: "paragraph", content: [] }, { type: "doc", content: "x" }, { type: "doc" }]) {
      expect(cleanDoc(bad)).toEqual({ doc: null, problem: "shape" });
    }
  });

  it("keeps list items inside lists and text inside blocks", () => {
    const { doc: clean, problem } = cleanDoc(doc({ type: "bulletList", content: [p("not an item"), item("item")] }, { type: "text", text: "loose" }));
    expect(clean).toEqual(doc({ type: "bulletList", content: [item("item")] }));
    expect(problem).toBe("node");
  });

  it("refuses heading levels other than the two it offers", () => {
    const { doc: clean, problem } = cleanDoc(doc({ type: "heading", attrs: { level: 1 }, content: [{ type: "text", text: "H1" }] }));
    expect(clean).toEqual(doc(p("H1")));
    expect(problem).toBe("node");
  });

  it("stops at the depth limit", () => {
    let node: unknown = p("deep");
    for (let i = 0; i < MAX_DEPTH + 2; i++) node = { type: "blockquote", content: [node] };
    expect(cleanDoc(doc(node)).problem).toBe("depth");
  });

  it("removes control characters from text and blank paragraphs at the ends", () => {
    const { doc: clean } = cleanDoc(doc({ type: "paragraph" }, p("a\u0000b\u001bc"), { type: "paragraph" }, p("d"), { type: "paragraph", content: [{ type: "text", text: "  " }] }));
    expect(clean).toEqual(doc(p("abc"), { type: "paragraph" }, p("d")));
  });
});

describe("docToPlainText", () => {
  it("writes one block per line, lists with their markers, breaks as breaks", () => {
    const d = cleanDoc(
      doc(
        { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "Title" }] },
        { type: "paragraph", content: [{ type: "text", text: "Line one" }, { type: "hardBreak" }, { type: "text", text: "line two", marks: [{ type: "bold" }] }] },
        { type: "bulletList", content: [item("first"), { type: "listItem", content: [p("second"), { type: "bulletList", content: [item("nested")] }] }] },
        { type: "orderedList", attrs: { start: 4 }, content: [item("four"), item("five")] },
        { type: "blockquote", content: [p("quoted")] },
        p("see the page", [{ type: "link", attrs: { href: "/subscriptions" } }]),
      ),
    ).doc as RichDoc;
    expect(docToPlainText(d)).toBe(["Title", "Line one", "line two", "- first", "- second", "  - nested", "4. four", "5. five", "quoted", "see the page"].join("\n"));
  });

  it("keeps a single blank line for empty paragraphs", () => {
    const d = cleanDoc(doc(p("a"), { type: "paragraph" }, { type: "paragraph" }, { type: "paragraph" }, p("b"))).doc as RichDoc;
    expect(docToPlainText(d)).toBe("a\n\nb");
  });

  it("round-trips plain text through textToDoc", () => {
    expect(docToPlainText(textToDoc("Hello\n\nWorld\r\nAgain"))).toBe("Hello\n\nWorld\nAgain");
  });
});

describe("parseNoticeDoc", () => {
  it("returns the clean document and its plain text", () => {
    const parsed = parseNoticeDoc(JSON.stringify(doc(p("Hi", [{ type: "bold" }]), { type: "bulletList", content: [item("one")] })));
    expect(parsed).toEqual({ ok: true, doc: doc(p("Hi", [{ type: "bold" }]), { type: "bulletList", content: [item("one")] }), text: "Hi\n- one" });
  });

  it("refuses broken JSON, other shapes, unknown nodes and empty notices", () => {
    expect(parseNoticeDoc("{not json")).toEqual({ ok: false, error: "bad_body" });
    expect(parseNoticeDoc(undefined)).toEqual({ ok: false, error: "bad_body" });
    expect(parseNoticeDoc(JSON.stringify([p("x")]))).toEqual({ ok: false, error: "bad_body" });
    expect(parseNoticeDoc(JSON.stringify(doc({ type: "codeBlock", content: [{ type: "text", text: "x" }] }, p("y"))))).toEqual({ ok: false, error: "bad_body" });
    expect(parseNoticeDoc(JSON.stringify(doc({ type: "paragraph" }, p("   "))))).toEqual({ ok: false, error: "bad_body" });
  });

  it("refuses a link that is not https or a portal path, with its own reason", () => {
    for (const href of ["javascript:alert(1)", "//evil.example", "http://plain.example", "data:text/html,x"]) {
      expect(parseNoticeDoc(JSON.stringify(doc(p("x", [{ type: "link", attrs: { href } }])))), href).toEqual({ ok: false, error: "bad_text_link" });
    }
  });

  it("refuses text over the limit and documents over the size", () => {
    expect(parseNoticeDoc(JSON.stringify(doc(p("x".repeat(MAX_TEXT)))))).toMatchObject({ ok: true });
    expect(parseNoticeDoc(JSON.stringify(doc(p("x".repeat(MAX_TEXT + 1)))))).toEqual({ ok: false, error: "bad_body" });
    // Short text with heavy formatting: many bold, italic, linked one-letter words.
    const marks = [{ type: "bold" }, { type: "italic" }, { type: "underline" }, { type: "strike" }, { type: "link", attrs: { href: "https://busin.example/a/long/path/to/make/it/bigger" } }];
    const heavy = doc({ type: "paragraph", content: Array.from({ length: 300 }, (_, i) => ({ type: "text", text: String(i % 10), marks: i % 2 ? marks : marks.slice(0, 4) })) });
    expect(JSON.stringify(heavy).length).toBeGreaterThan(MAX_DOC_BYTES);
    expect(parseNoticeDoc(JSON.stringify(heavy))).toEqual({ ok: false, error: "bad_body" });
  });
});
