import Link from "next/link";
import type { ReactNode } from "react";
import { LinkSquare02Icon } from "@hugeicons/core-free-icons";

import { Icon } from "@/components/ui/Icon";
import { cleanDoc, isExternalHref, isSafeHref, type RichBlock, type RichInline, type RichListItem, type RichText as RichTextNode } from "@/lib/rich-text";

type Props = {
  /** A stored document. Anything outside the whitelist is left out; text is always text. */
  doc: unknown;
  /** The HTML level of the document's large headings (its small ones are one below), to fit the page's outline. */
  headingLevel?: 2 | 3 | 4;
  /** Read by screen readers after a link that opens in a new tab. */
  newTabLabel?: string;
  /** False draws links as link-coloured words that lead nowhere (a preview). */
  linkable?: boolean;
  className?: string;
};

type Ctx = { headingLevel: 2 | 3 | 4; newTabLabel: string; linkable: boolean };

const LINK =
  "font-semibold text-link no-underline transition-colors duration-(--dur-fast) hover:text-fg " +
  "focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus";

/** The words of a text node with its marks, the link aside (a link may span several nodes). */
function marked(node: RichTextNode, key: number): ReactNode {
  let out: ReactNode = node.text;
  const has = (type: string) => (node.marks ?? []).some((m) => m.type === type);
  if (has("strike")) out = <s>{out}</s>;
  if (has("underline")) out = <u className="underline decoration-1 underline-offset-2">{out}</u>;
  if (has("italic")) out = <em>{out}</em>;
  if (has("bold")) out = <strong className="font-bold">{out}</strong>;
  return <span key={key}>{out}</span>;
}

function hrefOf(node: RichInline): string | null {
  if (node.type !== "text") return null;
  const link = node.marks?.find((m) => m.type === "link");
  // The link was checked when the document was read; checked again here, so a renderer change cannot skip it.
  return link && link.type === "link" && isSafeHref(link.attrs.href) ? link.attrs.href : null;
}

function linked(href: string, children: ReactNode[], key: number, ctx: Ctx): ReactNode {
  const external = isExternalHref(href);
  const inner = (
    <>
      {children}
      {external ? <Icon icon={LinkSquare02Icon} size={13} className="ml-0.5 inline-block align-[-1px]" /> : null}
      {external && ctx.linkable ? <span className="sr-only"> ({ctx.newTabLabel})</span> : null}
    </>
  );
  if (!ctx.linkable) {
    return (
      <span key={key} className={LINK}>
        {inner}
      </span>
    );
  }
  return external ? (
    <a key={key} href={href} target="_blank" rel="noopener noreferrer" className={LINK}>
      {inner}
    </a>
  ) : (
    <Link key={key} href={href} rel="noopener noreferrer" className={LINK}>
      {inner}
    </Link>
  );
}

/** Inline content: neighbouring words with the same link become one link. */
function inline(nodes: RichInline[] | undefined, ctx: Ctx): ReactNode[] {
  const list = nodes ?? [];
  const out: ReactNode[] = [];
  for (let i = 0; i < list.length; ) {
    const node = list[i];
    if (node.type === "hardBreak") {
      out.push(<br key={i} />);
      i += 1;
      continue;
    }
    const href = hrefOf(node);
    if (!href) {
      out.push(marked(node, i));
      i += 1;
      continue;
    }
    const start = i;
    const run: ReactNode[] = [];
    while (i < list.length && list[i].type === "text" && hrefOf(list[i]) === href) {
      run.push(marked(list[i] as RichTextNode, i));
      i += 1;
    }
    out.push(linked(href, run, start, ctx));
  }
  return out;
}

function items(list: RichListItem[], ctx: Ctx): ReactNode[] {
  return list.map((item, i) => (
    <li key={i} className="pl-1 marker:text-muted [&>*+*]:mt-1">
      {item.content.map((b, j) => block(b, j, ctx))}
    </li>
  ));
}

function block(node: RichBlock, key: number, ctx: Ctx): ReactNode {
  switch (node.type) {
    case "paragraph":
      // An empty paragraph is a blank line the writer left on purpose.
      return node.content && node.content.length > 0 ? (
        <p key={key} className="m-0">
          {inline(node.content, ctx)}
        </p>
      ) : (
        <p key={key} className="m-0 h-2" aria-hidden />
      );
    case "heading": {
      const level = node.attrs.level === 2 ? ctx.headingLevel : Math.min(ctx.headingLevel + 1, 6);
      const Tag = `h${level}` as "h2" | "h3" | "h4" | "h5";
      return (
        <Tag key={key} className={`m-0 font-bold text-fg ${node.attrs.level === 2 ? "text-base" : "text-sm"} [&:not(:first-child)]:mt-1`}>
          {inline(node.content, ctx)}
        </Tag>
      );
    }
    case "bulletList":
      return (
        <ul key={key} className="m-0 list-disc pl-5 [&>*+*]:mt-1">
          {items(node.content, ctx)}
        </ul>
      );
    case "orderedList":
      return (
        <ol key={key} start={node.attrs?.start} className="m-0 list-decimal pl-5 [&>*+*]:mt-1">
          {items(node.content, ctx)}
        </ol>
      );
    case "blockquote":
      // A tinted, rounded block: no one-sided rule (design system).
      return (
        <blockquote key={key} className="m-0 rounded-xs bg-[color-mix(in_srgb,var(--fg)_6%,transparent)] px-3.5 py-2.5 italic [&>*+*]:mt-2">
          {node.content.map((b, j) => block(b, j, ctx))}
        </blockquote>
      );
  }
}

/**
 * Shows a rich text document (from RichTextEditor) as React elements: paragraphs, two heading sizes, lists, quotes,
 * bold, italic, underline, strikethrough, links and line breaks. It never reads HTML: only the whitelisted node and mark
 * types are drawn, anything else is dropped, and a link is drawn only for https:// or a portal path. Server-safe.
 */
export function RichText({ doc, headingLevel = 3, newTabLabel = "opens in a new tab", linkable = true, className = "" }: Props) {
  const { doc: clean } = cleanDoc(doc);
  if (!clean || clean.content.length === 0) return null;
  const ctx: Ctx = { headingLevel, newTabLabel, linkable };
  return (
    <div className={`min-w-0 break-words [&>*+*]:mt-2 ${className}`} data-rich-text="">
      {clean.content.map((b, i) => block(b, i, ctx))}
    </div>
  );
}
