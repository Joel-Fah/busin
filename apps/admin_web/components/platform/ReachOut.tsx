"use client";

import { useMemo, useState } from "react";
import {
  ArrowRight01Icon,
  Call02Icon,
  Calendar02Icon,
  Cancel01Icon,
  Mail01Icon,
  Megaphone01Icon,
  Message01Icon,
  NoteEditIcon,
  PauseIcon,
  WhatsappIcon,
} from "@hugeicons/core-free-icons";

import { NoticeCard } from "@/components/overview/NoticeCard";
import { Button } from "@/components/ui/Button";
import { DatePicker, type DatePickerText } from "@/components/ui/DatePicker";
import { Icon } from "@/components/ui/Icon";
import { RichTextEditor } from "@/components/ui/RichTextEditor";
import { Select } from "@/components/ui/Select";
import { SideSheet } from "@/components/ui/SideSheet";
import { Textarea } from "@/components/ui/Textarea";
import { format } from "@/lib/i18n/format";
import type { Locale, Messages } from "@/lib/i18n/messages";
import type { Signal } from "@/lib/platform-health";
import { CHANNELS, SNOOZE_DAYS, mailtoHref, readyMessage, whatsappHref, type Contact, type MessageCopy } from "@/lib/platform-outreach";
import { MAX_TEXT, type RichDoc } from "@/lib/rich-text";

type Props = {
  schoolId: string;
  schoolName: string;
  siteUrl: string;
  /** The signals a message may be about: Watch or worse, plus any paused ones. */
  signals: Signal[];
  /** Paused signals and the date they are paused until, ready to show. */
  snoozed: Record<string, string>;
  contacts: Contact[];
  copy: Record<Locale, MessageCopy>;
  language: Locale;
  text: Messages["platform"]["outreach"];
  /** The notice editor's toolbar and count, in the console's language. */
  editorText: Messages["richText"];
  /** Short names of the signals, by key. */
  titles: Record<string, string>;
  closeLabel: string;
  dateText: DatePickerText;
  today: string;
  sendNotice: (formData: FormData) => Promise<void>;
  logOutreach: (formData: FormData) => Promise<void>;
};

/** Contacts shown at once; the rest open under "Show more". */
const SHOWN = 3;

const PILL =
  "inline-flex items-center gap-1.5 rounded-sm px-3 py-1.5 text-sm font-semibold no-underline " +
  "transition-colors duration-(--dur-fast) focus-visible:outline-3 focus-visible:outline-focus";
const LINK = `${PILL} bg-surface-2 text-fg hover:bg-[color-mix(in_srgb,var(--fg)_9%,transparent)]`;
const ICON_LINK =
  "grid size-9 place-items-center rounded-sm bg-surface text-fg no-underline transition-colors duration-(--dur-fast) " +
  "hover:bg-[color-mix(in_srgb,var(--fg)_9%,transparent)] focus-visible:outline-3 focus-visible:outline-focus";

/**
 * Reaching out to a school (ADR 0027). The page shows who to contact and two actions. "Write a message" opens a side
 * panel: pick the signals and the language, and the message is written; it opens in the owner's own email or WhatsApp
 * (nothing is sent for them), or goes to the school's administrators as a notice in their portal. "Log a contact"
 * records a call, a meeting or a message sent elsewhere. Both can pause the signals for a while and set a follow-up.
 */
export function ReachOut(props: Props) {
  const { schoolId, schoolName, siteUrl, signals, snoozed, contacts, copy, text, titles, closeLabel, dateText, today } = props;
  const [open, setOpen] = useState<"message" | "log" | null>(null);
  const [chosen, setChosen] = useState<Set<string>>(() => new Set(signals.filter((s) => s.level > 0 && !snoozed[s.signal]).map((s) => s.signal)));
  const [language, setLanguage] = useState<Locale>(props.language);
  const [snooze, setSnooze] = useState("7");
  const [followUp, setFollowUp] = useState("");

  const picked = useMemo(() => signals.filter((s) => chosen.has(s.signal)), [signals, chosen]);
  const ready = useMemo(() => readyMessage(schoolName, picked, copy[language], language, siteUrl), [schoolName, picked, copy, language, siteUrl]);
  // The texts follow the choices until edited; a new choice writes them again (the notice editor starts afresh).
  const [edited, setEdited] = useState<{ key: string; body: string } | null>(null);
  const [noticeEdit, setNoticeEdit] = useState<{ key: string; doc: RichDoc; text: string } | null>(null);
  const key = `${language}:${[...chosen].sort().join(",")}`;
  const body = edited?.key === key ? edited.body : ready.body;
  const notice = noticeEdit?.key === key ? noticeEdit : { doc: ready.noticeDoc, text: ready.notice };
  const noticeOk = notice.text.length > 0 && notice.text.length <= MAX_TEXT;
  const noticeCopy = copy[language].notice;

  const toggle = (signal: string) =>
    setChosen((current) => {
      const next = new Set(current);
      if (next.has(signal)) next.delete(signal);
      else next.add(signal);
      return next;
    });

  // The links for one contact, with the message as it stands.
  const links = (contact: Contact, withLabels: boolean) => {
    const wa = contact.phone ? whatsappHref(contact.phone, body) : null;
    const style = withLabels ? LINK : ICON_LINK;
    return (
      <div className="flex shrink-0 flex-wrap gap-1.5">
        {contact.email ? (
          <a
            className={style}
            href={mailtoHref(contact.email, ready.subject, body)}
            target="_blank"
            rel="noreferrer"
            aria-label={withLabels ? undefined : text.email}
            data-tip={withLabels ? undefined : text.email}
          >
            <Icon icon={Mail01Icon} size={16} />
            {withLabels ? text.email : null}
          </a>
        ) : null}
        {wa ? (
          <a className={style} href={wa} target="_blank" rel="noreferrer" aria-label={withLabels ? undefined : text.whatsapp} data-tip={withLabels ? undefined : text.whatsapp}>
            <Icon icon={WhatsappIcon} size={16} />
            {withLabels ? text.whatsapp : null}
          </a>
        ) : null}
        {contact.phone && !withLabels ? (
          <a className={style} href={`tel:${contact.phone}`} aria-label={text.call} data-tip={text.call}>
            <Icon icon={Call02Icon} size={16} />
          </a>
        ) : null}
      </div>
    );
  };

  const contactRow = (contact: Contact, index: number, withLabels: boolean) => (
    <li key={`${contact.label}-${index}`} className={`flex items-center justify-between gap-3 rounded-md bg-surface-2/60 px-3 py-2.5 ${withLabels ? "flex-wrap" : ""}`}>
      <div className="min-w-0">
        <p className="m-0 truncate text-sm font-semibold">{contact.name ?? contact.email ?? contact.phone}</p>
        <p className="m-0 truncate text-xs text-muted">{contact.name && contact.email ? `${contact.label} · ${contact.email}` : contact.label}</p>
      </div>
      {links(contact, withLabels)}
    </li>
  );

  const contactList = (withLabels: boolean) =>
    contacts.length === 0 ? (
      <p className="m-0 text-sm text-muted">{text.noContacts}</p>
    ) : (
      <div data-testid={withLabels ? "message-contacts" : "reach-contacts"} className="flex flex-col gap-2">
        <ul className="m-0 flex list-none flex-col gap-2 p-0">{contacts.slice(0, SHOWN).map((c, i) => contactRow(c, i, withLabels))}</ul>
        {contacts.length > SHOWN ? (
          <details>
            <summary className="cursor-pointer text-sm font-semibold text-link">{format(text.moreContacts, { n: contacts.length - SHOWN })}</summary>
            <ul className="m-0 mt-2 flex list-none flex-col gap-2 p-0">{contacts.slice(SHOWN).map((c, i) => contactRow(c, i + SHOWN, withLabels))}</ul>
          </details>
        ) : null}
      </div>
    );

  // Pause and follow-up, in both panels (kept in state, sent as hidden fields); each panel has its own field ids.
  const pauseAndFollowUp = (panel: "notice" | "log") => (
    <div className="grid gap-4 sm:grid-cols-2">
      <Select
        id={`reach-snooze-${panel}`}
        label={text.snooze}
        icon={PauseIcon}
        value={snooze}
        onChange={setSnooze}
        options={SNOOZE_DAYS.map((d) => ({ value: String(d), label: text.snoozeOptions[String(d) as keyof typeof text.snoozeOptions] }))}
      />
      <DatePicker id={`reach-follow-up-${panel}`} label={text.followUp} value={followUp} onChange={setFollowUp} min={today} locale={language} text={dateText} />
    </div>
  );

  const hidden = (
    <>
      <input type="hidden" name="school" value={schoolId} />
      {picked.map((s) => (
        <input key={s.signal} type="hidden" name="signal" value={s.signal} />
      ))}
      <input type="hidden" name="snooze" value={snooze} />
      <input type="hidden" name="followUp" value={followUp} />
    </>
  );

  const topics = (
    <fieldset className="m-0 border-0 p-0">
      <legend className="mb-2 text-sm font-semibold">{text.about}</legend>
      <div className="flex flex-wrap gap-1.5">
        {signals.map((s) => (
          <button
            key={s.signal}
            type="button"
            aria-pressed={chosen.has(s.signal)}
            onClick={() => toggle(s.signal)}
            className={`${chosen.has(s.signal) ? `${PILL} bg-accent text-on-accent` : LINK} cursor-pointer border-0`}
          >
            {titles[s.signal] ?? s.signal}
            {snoozed[s.signal] ? <span className="text-xs font-normal opacity-80">{format(text.paused, { date: snoozed[s.signal] })}</span> : null}
          </button>
        ))}
      </div>
    </fieldset>
  );

  return (
    <div className="flex flex-col gap-4">
      {contactList(false)}
      <div className="flex flex-wrap gap-2">
        <Button icon={Message01Icon} onClick={() => setOpen("message")}>
          {text.write}
        </Button>
        <Button variant="secondary" icon={NoteEditIcon} onClick={() => setOpen("log")}>
          {text.log}
        </Button>
      </div>

      <SideSheet open={open === "message"} onClose={() => setOpen(null)} title={text.write} closeLabel={closeLabel}>
        <div className="flex flex-col gap-5">
          {topics}
          <div role="group" aria-label={text.language} className="flex gap-1.5">
            {(["en", "fr"] as const).map((l) => (
              <button
                key={l}
                type="button"
                aria-pressed={language === l}
                onClick={() => setLanguage(l)}
                className={`${language === l ? `${PILL} bg-accent text-on-accent` : LINK} cursor-pointer border-0`}
              >
                {l === "en" ? "English" : "Français"}
              </button>
            ))}
          </div>
          <Textarea
            id="reach-message"
            label={text.messageLabel}
            icon={Message01Icon}
            rows={9}
            value={body}
            onChange={(event) => setEdited({ key, body: event.currentTarget.value })}
          />
          <section aria-label={text.sendWith} className="flex flex-col gap-2">
            <p className="m-0 text-sm font-semibold">{text.sendWith}</p>
            {contactList(true)}
          </section>
          <details className="rounded-md bg-surface-2/60 p-4">
            <summary className="cursor-pointer font-semibold">{text.sendNotice}</summary>
            <form action={props.sendNotice} className="mt-4 flex flex-col gap-4">
              {hidden}
              <input type="hidden" name="link" value={ready.link ?? ""} />
              <p className="m-0 text-sm text-muted">{text.noticeHint}</p>
              <RichTextEditor
                key={key}
                id="reach-notice"
                name="notice_doc"
                label={text.noticeLabel}
                text={props.editorText}
                initial={ready.noticeDoc}
                placeholder={text.noticePlaceholder}
                onChange={(doc, plain) => setNoticeEdit({ key, doc, text: plain })}
              />
              <section aria-label={text.preview} className="flex flex-col gap-2" data-testid="notice-preview">
                <p className="m-0 text-sm font-semibold">{text.preview}</p>
                {/* A preview: its links and buttons are drawn but lead nowhere. */}
                <NoticeCard
                  preview
                  title={noticeCopy.from}
                  doc={notice.doc}
                  text={notice.text}
                  labels={noticeCopy}
                  actions={
                    <>
                      {ready.link ? (
                        <Button type="button" variant="secondary" icon={ArrowRight01Icon} disabled>
                          {noticeCopy.open}
                        </Button>
                      ) : null}
                      <Button type="button" variant="ghost" icon={Cancel01Icon} disabled>
                        {noticeCopy.dismiss}
                      </Button>
                    </>
                  }
                />
              </section>
              {pauseAndFollowUp("notice")}
              <div>
                <Button type="submit" icon={Megaphone01Icon} disabled={!noticeOk}>
                  {text.sendNoticeButton}
                </Button>
              </div>
            </form>
          </details>
        </div>
      </SideSheet>

      <SideSheet open={open === "log"} onClose={() => setOpen(null)} title={text.log} closeLabel={closeLabel}>
        <form action={props.logOutreach} className="flex flex-col gap-5">
          {hidden}
          {topics}
          <Select
            id="reach-channel"
            name="channel"
            label={text.channel}
            icon={Calendar02Icon}
            defaultValue="email"
            options={CHANNELS.filter((c) => c !== "notice").map((c) => ({ value: c, label: text.channels[c] }))}
          />
          <Textarea id="reach-note" name="note" label={text.note} icon={NoteEditIcon} placeholder={text.notePlaceholder} rows={3} maxLength={1000} />
          {pauseAndFollowUp("log")}
          <div>
            <Button type="submit" icon={NoteEditIcon}>
              {text.save}
            </Button>
          </div>
        </form>
      </SideSheet>
    </div>
  );
}
