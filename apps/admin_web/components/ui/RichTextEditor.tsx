"use client";

import { Fragment, useEffect, useMemo, useRef, useState, useSyncExternalStore, type KeyboardEvent } from "react";
import { EditorContent, useEditor, useEditorState, type Editor, type JSONContent } from "@tiptap/react";
import { Extension } from "@tiptap/core";
import StarterKit from "@tiptap/starter-kit";
import { Placeholder } from "@tiptap/extensions";
import type { IconSvgElement } from "@hugeicons/react";
import {
  Heading02Icon,
  Heading03Icon,
  LeftToRightBlockQuoteIcon,
  LeftToRightListBulletIcon,
  LeftToRightListNumberIcon,
  Link01Icon,
  Redo02Icon,
  TextBoldIcon,
  TextItalicIcon,
  TextStrikethroughIcon,
  TextUnderlineIcon,
  Undo02Icon,
  Unlink01Icon,
} from "@hugeicons/core-free-icons";

import { Button } from "./Button";
import { Icon } from "./Icon";
import { Input } from "./Input";
import { format } from "@/lib/i18n/format";
import type { Messages } from "@/lib/i18n/messages";
import { cleanDoc, docToPlainText, isSafeHref, MAX_TEXT, type RichDoc } from "@/lib/rich-text";

export type RichTextEditorText = Messages["richText"];

type Props = {
  id: string;
  label: string;
  text: RichTextEditorText;
  /** The document it starts with. To start again from another document, give the editor a new React key. */
  initial?: RichDoc;
  placeholder?: string;
  hint?: string;
  /** The most characters of plain text (the server checks the same). */
  maxLength?: number;
  /** Sends the document as JSON with the form, under this name. */
  name?: string;
  onChange?: (doc: RichDoc, plain: string) => void;
};

type Tool = {
  key: string;
  group: number;
  label: string;
  icon: IconSvgElement;
  /** What follows Ctrl (Cmd on a Mac), as TipTap binds it. */
  keys: string;
  /** A toggle shows whether it is on; undo and redo are plain buttons. */
  toggle: boolean;
  active?: boolean;
  disabled?: boolean;
  run: () => void;
};

const TOOL =
  "grid size-9 shrink-0 cursor-pointer place-items-center rounded-xs border-0 bg-transparent text-fg " +
  "transition-colors duration-(--dur-fast) hover:bg-[color-mix(in_srgb,var(--fg)_9%,transparent)] " +
  "focus-visible:outline-3 focus-visible:outline-offset-1 focus-visible:outline-focus " +
  "aria-pressed:bg-accent aria-pressed:text-on-accent aria-pressed:hover:bg-accent " +
  "aria-disabled:cursor-default aria-disabled:opacity-40 aria-disabled:hover:bg-transparent";

const isMac = () => /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);
const noSubscription = () => () => {};
const plainOf = (value: unknown) => {
  const { doc } = cleanDoc(value);
  return doc ? docToPlainText(doc) : "";
};

/**
 * A rich text field: bold, italic, underline, strikethrough, two heading sizes, bulleted and numbered lists, quotes,
 * links and line breaks (Shift+Enter), with undo and redo and a character count. Built on TipTap; what it produces is a
 * JSON document (see lib/rich-text.ts), never HTML, and the server checks it again before saving. Links take only
 * https:// or a page of the portal. The toolbar wraps on a narrow screen and is one tab stop: arrows move along it.
 */
export function RichTextEditor({ id, label, text, initial, placeholder, hint, maxLength = MAX_TEXT, name, onChange }: Props) {
  const [doc, setDoc] = useState<JSONContent>(() => initial ?? { type: "doc", content: [{ type: "paragraph" }] });
  const [count, setCount] = useState(() => plainOf(initial).length);
  const [linkOpen, setLinkOpen] = useState(false);
  const [linkValue, setLinkValue] = useState("");
  const [linkError, setLinkError] = useState<string | null>(null);
  const [focusIndex, setFocusIndex] = useState(0);
  // Shortcuts are written the way the person's keyboard says them.
  const mod = useSyncExternalStore(noSubscription, () => (isMac() ? "Cmd" : "Ctrl"), () => "Ctrl");
  const toolbarRef = useRef<HTMLDivElement>(null);
  const openLinkRef = useRef<() => void>(() => {});
  const onChangeRef = useRef(onChange);
  useEffect(() => {
    onChangeRef.current = onChange;
  }, [onChange]);

  const extensions = useMemo(
    () => [
      StarterKit.configure({
        heading: { levels: [2, 3] },
        code: false,
        codeBlock: false,
        horizontalRule: false,
        link: {
          openOnClick: false,
          autolink: true,
          linkOnPaste: true,
          defaultProtocol: "https",
          isAllowedUri: (url) => isSafeHref(url),
          shouldAutoLink: (url) => isSafeHref(url),
          HTMLAttributes: { rel: "noopener noreferrer", target: null },
        },
      }),
      Placeholder.configure({ placeholder: placeholder ?? "" }),
      // Ctrl+K (Cmd+K) opens the link field, as in most editors.
      Extension.create({
        name: "linkShortcut",
        addKeyboardShortcuts() {
          return {
            "Mod-k": () => {
              openLinkRef.current();
              return true;
            },
          };
        },
      }),
    ],
    [placeholder],
  );

  const editor = useEditor({
    extensions,
    content: doc,
    immediatelyRender: false,
    editorProps: {
      attributes: {
        id,
        role: "textbox",
        "aria-multiline": "true",
        "aria-labelledby": `${id}-label`,
        "aria-describedby": `${id}-count${hint ? ` ${id}-hint` : ""}`,
        class: "tiptap px-4 py-3 text-sm text-fg",
      },
    },
    onUpdate: ({ editor: e }) => {
      const json = e.getJSON();
      setDoc(json);
      const { doc: clean } = cleanDoc(json);
      const plain = clean ? docToPlainText(clean) : "";
      setCount(plain.length);
      if (clean) onChangeRef.current?.(clean, plain);
    },
  });

  const state = useEditorState({
    editor,
    selector: ({ editor: e }: { editor: Editor | null }) =>
      e
        ? {
            bold: e.isActive("bold"),
            italic: e.isActive("italic"),
            underline: e.isActive("underline"),
            strike: e.isActive("strike"),
            h2: e.isActive("heading", { level: 2 }),
            h3: e.isActive("heading", { level: 3 }),
            bullet: e.isActive("bulletList"),
            ordered: e.isActive("orderedList"),
            quote: e.isActive("blockquote"),
            link: e.isActive("link"),
            canUndo: e.can().undo(),
            canRedo: e.can().redo(),
          }
        : null,
  });

  const openLink = () => {
    if (!editor) return;
    setLinkValue((editor.getAttributes("link").href as string | undefined) ?? "");
    setLinkError(null);
    setLinkOpen(true);
  };
  useEffect(() => {
    openLinkRef.current = openLink;
  });

  const closeLink = () => {
    setLinkOpen(false);
    setLinkError(null);
    editor?.commands.focus();
  };

  const applyLink = () => {
    if (!editor) return;
    const href = linkValue.trim();
    if (!isSafeHref(href)) {
      setLinkError(text.linkInvalid);
      return;
    }
    if (editor.state.selection.empty && !editor.isActive("link")) {
      // Nothing selected: the address itself becomes the linked words.
      editor.chain().focus().insertContent({ type: "text", text: href, marks: [{ type: "link", attrs: { href } }] }).run();
    } else {
      editor.chain().focus().extendMarkRange("link").setLink({ href }).run();
    }
    setLinkOpen(false);
    setLinkError(null);
  };

  const removeLink = () => {
    editor?.chain().focus().extendMarkRange("link").unsetLink().run();
    setLinkOpen(false);
    setLinkError(null);
  };

  const command = (run: (e: Editor) => void) => () => {
    if (editor) run(editor);
  };
  const tools: Tool[] = [
    { key: "bold", group: 0, label: text.bold, icon: TextBoldIcon, keys: "B", toggle: true, active: state?.bold, run: command((e) => e.chain().focus().toggleBold().run()) },
    { key: "italic", group: 0, label: text.italic, icon: TextItalicIcon, keys: "I", toggle: true, active: state?.italic, run: command((e) => e.chain().focus().toggleItalic().run()) },
    { key: "underline", group: 0, label: text.underline, icon: TextUnderlineIcon, keys: "U", toggle: true, active: state?.underline, run: command((e) => e.chain().focus().toggleUnderline().run()) },
    { key: "strike", group: 0, label: text.strike, icon: TextStrikethroughIcon, keys: "Shift+S", toggle: true, active: state?.strike, run: command((e) => e.chain().focus().toggleStrike().run()) },
    { key: "h2", group: 1, label: text.heading, icon: Heading02Icon, keys: "Alt+2", toggle: true, active: state?.h2, run: command((e) => e.chain().focus().toggleHeading({ level: 2 }).run()) },
    { key: "h3", group: 1, label: text.subheading, icon: Heading03Icon, keys: "Alt+3", toggle: true, active: state?.h3, run: command((e) => e.chain().focus().toggleHeading({ level: 3 }).run()) },
    { key: "bullet", group: 2, label: text.bulletList, icon: LeftToRightListBulletIcon, keys: "Shift+8", toggle: true, active: state?.bullet, run: command((e) => e.chain().focus().toggleBulletList().run()) },
    { key: "ordered", group: 2, label: text.orderedList, icon: LeftToRightListNumberIcon, keys: "Shift+7", toggle: true, active: state?.ordered, run: command((e) => e.chain().focus().toggleOrderedList().run()) },
    { key: "quote", group: 2, label: text.quote, icon: LeftToRightBlockQuoteIcon, keys: "Shift+B", toggle: true, active: state?.quote, run: command((e) => e.chain().focus().toggleBlockquote().run()) },
    { key: "link", group: 2, label: text.link, icon: Link01Icon, keys: "K", toggle: true, active: state?.link || linkOpen, run: openLink },
    { key: "undo", group: 3, label: text.undo, icon: Undo02Icon, keys: "Z", toggle: false, disabled: !state?.canUndo, run: command((e) => e.chain().focus().undo().run()) },
    { key: "redo", group: 3, label: text.redo, icon: Redo02Icon, keys: "Shift+Z", toggle: false, disabled: !state?.canRedo, run: command((e) => e.chain().focus().redo().run()) },
  ];

  // One tab stop for the whole toolbar; the arrow keys, Home and End move along it.
  const onToolbarKey = (event: KeyboardEvent<HTMLDivElement>) => {
    const moves: Record<string, (i: number) => number> = {
      ArrowRight: (i) => (i + 1) % tools.length,
      ArrowLeft: (i) => (i - 1 + tools.length) % tools.length,
      Home: () => 0,
      End: () => tools.length - 1,
    };
    const move = moves[event.key];
    if (!move) return;
    event.preventDefault();
    const next = move(focusIndex);
    setFocusIndex(next);
    toolbarRef.current?.querySelectorAll<HTMLButtonElement>("button")[next]?.focus();
  };

  const over = count > maxLength;

  return (
    <div className="@container flex flex-col gap-1.5">
      <span id={`${id}-label`} className="text-sm font-semibold">
        {label}
      </span>
      <div
        className={
          "rich-editor rounded-sm border bg-surface transition-[border-color,box-shadow] duration-(--dur-fast) " +
          "focus-within:ring-3 focus-within:ring-focus/30 " +
          (over ? "border-bad" : "border-line focus-within:border-focus")
        }
      >
        <div
          ref={toolbarRef}
          role="toolbar"
          aria-label={text.toolbar}
          aria-controls={id}
          onKeyDown={onToolbarKey}
          className="flex flex-wrap items-center gap-px rounded-t-sm bg-surface-2/60 p-1.5"
        >
          {tools.map((tool, i) => {
            const shortcut = `${mod}+${tool.keys}`;
            return (
              <Fragment key={tool.key}>
                {i > 0 && tools[i - 1].group !== tool.group ? <span aria-hidden className="mx-0.5 h-5 w-px bg-line" /> : null}
                <button
                  type="button"
                  tabIndex={i === focusIndex ? 0 : -1}
                  aria-label={tool.label}
                  aria-pressed={tool.toggle ? Boolean(tool.active) : undefined}
                  aria-disabled={tool.disabled || !editor ? true : undefined}
                  aria-keyshortcuts={shortcut.replace("Ctrl", "Control").replace("Cmd", "Meta")}
                  data-tip={`${tool.label} (${shortcut})`}
                  data-tip-side="top"
                  // Keep the text selection in the editor while a tool is clicked.
                  onMouseDown={(event) => event.preventDefault()}
                  onFocus={() => setFocusIndex(i)}
                  onClick={() => {
                    if (!tool.disabled) tool.run();
                  }}
                  className={TOOL}
                >
                  <Icon icon={tool.icon} size={18} />
                </button>
              </Fragment>
            );
          })}
        </div>

        {linkOpen ? (
          <div className="flex flex-col gap-2 px-3 pt-3 @lg:flex-row @lg:items-start">
            <Input
              id={`${id}-link`}
              label={text.linkLabel}
              icon={Link01Icon}
              type="text"
              inputMode="url"
              placeholder="https://"
              // It opens because the person asked for it, so it takes the focus.
              autoFocus
              hint={text.linkHint}
              error={linkError ?? undefined}
              value={linkValue}
              onChange={(event) => {
                setLinkValue(event.currentTarget.value);
                setLinkError(null);
              }}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  event.preventDefault();
                  applyLink();
                } else if (event.key === "Escape") {
                  event.preventDefault();
                  event.stopPropagation();
                  closeLink();
                }
              }}
              className="min-w-0 flex-1"
            />
            <div className="flex flex-wrap gap-1.5 @lg:mt-7">
              <Button type="button" onClick={applyLink}>
                {text.linkApply}
              </Button>
              {state?.link ? (
                <Button type="button" variant="ghost" icon={Unlink01Icon} onClick={removeLink}>
                  {text.linkRemove}
                </Button>
              ) : null}
              <Button type="button" variant="ghost" onClick={closeLink}>
                {text.linkCancel}
              </Button>
            </div>
          </div>
        ) : null}

        {/* Holds the space of the text while the editor starts, so nothing jumps. */}
        <EditorContent editor={editor} className="min-h-32" />
      </div>
      <div className="flex flex-wrap items-start justify-between gap-x-4 gap-y-1 text-sm">
        {hint ? (
          <p id={`${id}-hint`} className="m-0 text-muted">
            {hint}
          </p>
        ) : (
          <span />
        )}
        <p id={`${id}-count`} className={`m-0 tabular-nums ${over ? "font-semibold text-bad" : "text-muted"}`}>
          {format(over ? text.tooLong : text.count, { n: count, max: maxLength })}
        </p>
      </div>
      {name ? <input type="hidden" name={name} value={JSON.stringify(doc)} /> : null}
    </div>
  );
}
