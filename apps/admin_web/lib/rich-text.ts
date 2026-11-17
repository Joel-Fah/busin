/**
 * Rich text as a document, never as HTML. The editor (TipTap) produces a JSON document; this module is the one place
 * that decides what such a document may hold: a short whitelist of nodes and marks, a depth and size limit, and links
 * that are either https:// or a page of the portal. The server action refuses anything else; the renderer drops it.
 * Pure TypeScript, so the server, the browser and the tests share it.
 */

export const BLOCKS = ["paragraph", "heading", "bulletList", "orderedList", "blockquote"] as const;
export const MARKS = ["bold", "italic", "underline", "strike", "link"] as const;
export type MarkType = (typeof MARKS)[number];

export type RichMark = { type: Exclude<MarkType, "link"> } | { type: "link"; attrs: { href: string } };
export type RichText = { type: "text"; text: string; marks?: RichMark[] };
export type RichBreak = { type: "hardBreak" };
export type RichInline = RichText | RichBreak;
export type RichParagraph = { type: "paragraph"; content?: RichInline[] };
export type RichHeading = { type: "heading"; attrs: { level: 2 | 3 }; content?: RichInline[] };
export type RichListItem = { type: "listItem"; content: RichBlock[] };
export type RichBulletList = { type: "bulletList"; content: RichListItem[] };
export type RichOrderedList = { type: "orderedList"; attrs?: { start: number }; content: RichListItem[] };
export type RichQuote = { type: "blockquote"; content: RichBlock[] };
export type RichBlock = RichParagraph | RichHeading | RichBulletList | RichOrderedList | RichQuote;
export type RichDoc = { type: "doc"; content: RichBlock[] };

/** Plain text a notice may hold (the database checks the same). */
export const MAX_TEXT = 4000;
/** Bytes of the compact JSON document. The database allows 32000 for its own, slightly wider, text form. */
export const MAX_DOC_BYTES = 24000;
/** Nesting levels, the document itself included (a list in a list in a quote stays well inside). */
export const MAX_DEPTH = 10;
/** Nodes in one document. */
export const MAX_NODES = 2000;
/** Characters of one link. */
export const MAX_HREF = 500;

/** The first thing wrong with a document, if anything. */
export type DocProblem = "shape" | "node" | "mark" | "link" | "depth" | "size";

/**
 * A link a notice may carry: an https:// address on a real host, or a page of the portal (a single "/", never "//",
 * which would leave the site). No spaces, control characters or backslashes, which browsers read in surprising ways.
 */
export function isSafeHref(value: unknown): value is string {
  if (typeof value !== "string" || value.length === 0 || value.length > MAX_HREF) return false;
  // Whitespace, controls and backslashes are refused outright rather than cleaned.
  if (/[\s\u0000-\u001f\u007f\\]/.test(value)) return false;
  if (value.startsWith("/")) return !value.startsWith("//");
  // A host right after the two slashes: "https:///x" would be read as a host named "x".
  if (!/^https:\/\/[^/]/i.test(value)) return false;
  try {
    const url = new URL(value);
    return url.protocol === "https:" && url.hostname.length > 0 && url.username === "" && url.password === "";
  } catch {
    return false;
  }
}

/** A link that leaves the portal (opened in a new tab). */
export function isExternalHref(href: string): boolean {
  return /^https:\/\//i.test(href);
}

type Raw = Record<string, unknown>;
const isRecord = (value: unknown): value is Raw => value !== null && typeof value === "object" && !Array.isArray(value);
// Text keeps line feeds out (a line break is its own node) and every other control character too.
const CONTROL = /[\u0000-\u0008\u000b-\u001f\u007f]/g;

type Walk = { problem: DocProblem | null; nodes: number };

function note(walk: Walk, problem: DocProblem) {
  walk.problem ??= problem;
}

function cleanMarks(value: unknown, walk: Walk): RichMark[] {
  if (value === undefined) return [];
  if (!Array.isArray(value)) {
    note(walk, "mark");
    return [];
  }
  const marks: RichMark[] = [];
  const seen = new Set<string>();
  for (const raw of value) {
    const type = isRecord(raw) ? raw.type : undefined;
    if (typeof type !== "string" || !(MARKS as readonly string[]).includes(type)) {
      note(walk, "mark");
      continue;
    }
    if (seen.has(type)) continue;
    if (type === "link") {
      const href = isRecord(raw) && isRecord(raw.attrs) ? raw.attrs.href : undefined;
      if (!isSafeHref(href)) {
        note(walk, "link");
        continue;
      }
      marks.push({ type: "link", attrs: { href } });
    } else {
      marks.push({ type: type as Exclude<MarkType, "link"> });
    }
    seen.add(type);
  }
  return marks;
}

function cleanInline(value: unknown, walk: Walk): RichInline[] {
  if (value === undefined) return [];
  if (!Array.isArray(value)) {
    note(walk, "shape");
    return [];
  }
  const out: RichInline[] = [];
  for (const raw of value) {
    if (++walk.nodes > MAX_NODES) {
      note(walk, "size");
      break;
    }
    if (!isRecord(raw)) {
      note(walk, "shape");
      continue;
    }
    if (raw.type === "hardBreak") {
      out.push({ type: "hardBreak" });
    } else if (raw.type === "text" && typeof raw.text === "string") {
      const text = raw.text.replace(CONTROL, "");
      if (text === "") continue;
      const marks = cleanMarks(raw.marks, walk);
      out.push(marks.length > 0 ? { type: "text", text, marks } : { type: "text", text });
    } else {
      note(walk, "node");
    }
  }
  return out;
}

function cleanBlocks(value: unknown, depth: number, walk: Walk): RichBlock[] {
  if (!Array.isArray(value)) {
    note(walk, "shape");
    return [];
  }
  if (depth > MAX_DEPTH) {
    note(walk, "depth");
    return [];
  }
  const out: RichBlock[] = [];
  for (const raw of value) {
    if (++walk.nodes > MAX_NODES) {
      note(walk, "size");
      break;
    }
    if (!isRecord(raw)) {
      note(walk, "shape");
      continue;
    }
    const block = cleanBlock(raw, depth, walk);
    if (block) out.push(block);
  }
  return out;
}

function cleanItems(value: unknown, depth: number, walk: Walk): RichListItem[] {
  if (!Array.isArray(value)) {
    note(walk, "shape");
    return [];
  }
  if (depth > MAX_DEPTH) {
    note(walk, "depth");
    return [];
  }
  const items: RichListItem[] = [];
  for (const raw of value) {
    if (++walk.nodes > MAX_NODES) {
      note(walk, "size");
      break;
    }
    if (!isRecord(raw) || raw.type !== "listItem") {
      note(walk, "node");
      continue;
    }
    const content = cleanBlocks(raw.content, depth + 1, walk);
    if (content.length > 0) items.push({ type: "listItem", content });
  }
  return items;
}

function cleanBlock(raw: Raw, depth: number, walk: Walk): RichBlock | null {
  switch (raw.type) {
    case "paragraph": {
      const content = cleanInline(raw.content, walk);
      return content.length > 0 ? { type: "paragraph", content } : { type: "paragraph" };
    }
    case "heading": {
      const level = isRecord(raw.attrs) ? raw.attrs.level : undefined;
      const content = cleanInline(raw.content, walk);
      if (level !== 2 && level !== 3) {
        // Another level is kept as its words, in a paragraph.
        note(walk, "node");
        return content.length > 0 ? { type: "paragraph", content } : null;
      }
      return content.length > 0 ? { type: "heading", attrs: { level }, content } : { type: "heading", attrs: { level } };
    }
    case "bulletList": {
      const content = cleanItems(raw.content, depth + 1, walk);
      return content.length > 0 ? { type: "bulletList", content } : null;
    }
    case "orderedList": {
      const content = cleanItems(raw.content, depth + 1, walk);
      if (content.length === 0) return null;
      const start = isRecord(raw.attrs) ? raw.attrs.start : undefined;
      return typeof start === "number" && Number.isInteger(start) && start > 1 && start < 10_000
        ? { type: "orderedList", attrs: { start }, content }
        : { type: "orderedList", content };
    }
    case "blockquote": {
      const content = cleanBlocks(raw.content, depth + 1, walk);
      return content.length > 0 ? { type: "blockquote", content } : null;
    }
    default:
      note(walk, "node");
      return null;
  }
}

const isEmptyParagraph = (block: RichBlock) => block.type === "paragraph" && !block.content?.some((n) => n.type === "text" && n.text.trim() !== "");

/**
 * Reads a document, keeping only what is allowed and only the attributes the renderer uses. Blank paragraphs at the
 * start and the end are left out. `problem` names the first thing that was dropped: the server refuses a document
 * with a problem, the renderer shows what is left.
 */
export function cleanDoc(value: unknown): { doc: RichDoc | null; problem: DocProblem | null } {
  if (!isRecord(value) || value.type !== "doc" || !Array.isArray(value.content)) return { doc: null, problem: "shape" };
  const walk: Walk = { problem: null, nodes: 1 };
  const content = cleanBlocks(value.content, 1, walk);
  while (content.length > 0 && isEmptyParagraph(content[0])) content.shift();
  while (content.length > 0 && isEmptyParagraph(content[content.length - 1])) content.pop();
  return { doc: { type: "doc", content }, problem: walk.problem };
}

function inlineText(nodes: RichInline[] | undefined): string {
  return (nodes ?? []).map((n) => (n.type === "text" ? n.text : "\n")).join("");
}

function blockLines(block: RichBlock): string[] {
  switch (block.type) {
    case "paragraph":
    case "heading":
      return inlineText(block.content).split("\n");
    case "blockquote":
      return block.content.flatMap(blockLines);
    case "bulletList":
    case "orderedList": {
      const start = block.type === "orderedList" ? (block.attrs?.start ?? 1) : 1;
      return block.content.flatMap((item, i) => {
        const marker = block.type === "orderedList" ? `${start + i}. ` : "- ";
        const lines = item.content.flatMap(blockLines);
        return lines.map((line, j) => (j === 0 ? marker : " ".repeat(marker.length)) + line);
      });
    }
  }
}

/**
 * The words of a document as plain text, one block per line: list items start with "- " or their number, line breaks
 * stay line breaks, links keep their words. Used for the outreach log, lists and the length limit.
 */
export function docToPlainText(doc: RichDoc): string {
  return doc.content
    .flatMap(blockLines)
    .map((line) => line.replace(/\s+$/, ""))
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

/** A document from plain text: one paragraph per line, blank lines kept as empty paragraphs. */
export function textToDoc(text: string): RichDoc {
  return {
    type: "doc",
    content: text
      .replace(/\r\n?/g, "\n")
      .split("\n")
      .map((line): RichParagraph => (line.trim() === "" ? { type: "paragraph" } : { type: "paragraph", content: [{ type: "text", text: line }] })),
  };
}

export type ParsedNotice = { ok: true; doc: RichDoc; text: string } | { ok: false; error: "bad_body" | "bad_text_link" };

/**
 * What the server does with the document sent by the editor (a JSON string from the form): parses it, refuses anything
 * outside the whitelist, too deep, too big or too long, and derives the plain text the database also checks.
 */
export function parseNoticeDoc(raw: unknown): ParsedNotice {
  if (typeof raw !== "string" || raw.length === 0 || raw.length > MAX_DOC_BYTES * 2) return { ok: false, error: "bad_body" };
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    return { ok: false, error: "bad_body" };
  }
  const { doc, problem } = cleanDoc(value);
  if (problem === "link") return { ok: false, error: "bad_text_link" };
  if (!doc || problem) return { ok: false, error: "bad_body" };
  if (new TextEncoder().encode(JSON.stringify(doc)).length > MAX_DOC_BYTES) return { ok: false, error: "bad_body" };
  const text = docToPlainText(doc);
  if (text.length === 0 || text.length > MAX_TEXT) return { ok: false, error: "bad_body" };
  return { ok: true, doc, text };
}
