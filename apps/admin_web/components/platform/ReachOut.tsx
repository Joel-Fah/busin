"use client";

import { useMemo, useState } from "react";
import {
  Call02Icon,
  Calendar02Icon,
  Mail01Icon,
  Megaphone01Icon,
  Message01Icon,
  NoteEditIcon,
  PauseIcon,
  WhatsappIcon,
} from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Checkbox } from "@/components/ui/Choice";
import { DatePicker, type DatePickerText } from "@/components/ui/DatePicker";
import { Select } from "@/components/ui/Select";
import { Textarea } from "@/components/ui/Textarea";
import type { Locale, Messages } from "@/lib/i18n/messages";
import { format } from "@/lib/i18n/format";
import type { Signal } from "@/lib/platform-health";
import { CHANNELS, SNOOZE_DAYS, mailtoHref, readyMessage, whatsappHref, type Contact, type MessageCopy } from "@/lib/platform-outreach";

type Props = {
  schoolId: string;
  schoolName: string;
  siteUrl: string;
  /** The signals a message may be about: Watch or worse, plus any paused ones. */
  signals: Signal[];
  /** Paused signals and until when (ISO dates). */
  snoozed: Record<string, string>;
  contacts: Contact[];
  copy: Record<Locale, MessageCopy>;
  language: Locale;
  text: Messages["platform"]["outreach"];
  titles: Record<string, string>;
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

/**
 * Reaching out to a school (ADR 0027): pick the signals to talk about and the language, and the message is written. It
 * opens in the owner's own email or WhatsApp for any contact (nothing is sent for them), or goes to the school's
 * administrators as a notice in their portal. Every contact can be logged, pausing its signals for a while and setting a
 * follow-up, so a school is not reminded twice for the same thing.
 */
export function ReachOut(props: Props) {
  const { schoolId, schoolName, siteUrl, signals, snoozed, contacts, copy, text, titles, dateText, today } = props;
  const [chosen, setChosen] = useState<Set<string>>(() => new Set(signals.filter((s) => s.level > 0 && !snoozed[s.signal]).map((s) => s.signal)));
  const [language, setLanguage] = useState<Locale>(props.language);
  const [snooze, setSnooze] = useState("7");
  const [followUp, setFollowUp] = useState("");

  const picked = useMemo(() => signals.filter((s) => chosen.has(s.signal)), [signals, chosen]);
  const ready = useMemo(() => readyMessage(schoolName, picked, copy[language], language, siteUrl), [schoolName, picked, copy, language, siteUrl]);
  // The texts follow the choices until edited; a new choice writes them again.
  const [edited, setEdited] = useState<{ key: string; body: string; notice: string } | null>(null);
  const key = `${language}:${[...chosen].sort().join(",")}`;
  const body = edited?.key === key ? edited.body : ready.body;
  const notice = edited?.key === key ? edited.notice : ready.notice;

  const toggle = (signal: string, on: boolean) =>
    setChosen((current) => {
      const next = new Set(current);
      if (on) next.add(signal);
      else next.delete(signal);
      return next;
    });

  const contactRow = (contact: Contact, index: number) => {
    const wa = contact.phone ? whatsappHref(contact.phone, body) : null;
    return (
      <li key={`${contact.label}-${index}`} className="flex flex-wrap items-center justify-between gap-2 rounded-md bg-surface-2/60 p-3">
        <div className="min-w-0">
          <p className="m-0 text-xs text-muted">{contact.label}</p>
          <p className="m-0 truncate font-semibold">{contact.name ?? contact.email ?? contact.phone}</p>
          {contact.name && contact.email ? <p className="m-0 truncate text-xs text-muted">{contact.email}</p> : null}
        </div>
        <div className="flex flex-wrap gap-1.5">
          {contact.email ? (
            <a className={LINK} href={mailtoHref(contact.email, ready.subject, body)} target="_blank" rel="noreferrer">
              <Icon icon={Mail01Icon} size={16} />
              {text.email}
            </a>
          ) : null}
          {wa ? (
            <a className={LINK} href={wa} target="_blank" rel="noreferrer">
              <Icon icon={WhatsappIcon} size={16} />
              {text.whatsapp}
            </a>
          ) : null}
          {contact.phone ? (
            <a className={LINK} href={`tel:${contact.phone}`}>
              <Icon icon={Call02Icon} size={16} />
              {text.call}
            </a>
          ) : null}
        </div>
      </li>
    );
  };

  const shared = (
    <>
      <input type="hidden" name="school" value={schoolId} />
      {picked.map((s) => (
        <input key={s.signal} type="hidden" name="signal" value={s.signal} />
      ))}
      <input type="hidden" name="snooze" value={snooze} />
      <input type="hidden" name="followUp" value={followUp} />
    </>
  );

  return (
    <div className="flex flex-col gap-6">
      <section aria-labelledby="reach-contacts" className="flex flex-col gap-3">
        <div>
          <h3 id="reach-contacts" className="text-base font-bold">
            {text.contacts}
          </h3>
          <p className="text-sm text-muted">{text.contactsHint}</p>
        </div>
        {contacts.length === 0 ? (
          <p className="m-0 text-sm text-muted">{text.noContacts}</p>
        ) : (
          <div data-testid="reach-contacts" className="flex flex-col gap-3">
            <ul className="m-0 flex list-none flex-col gap-3 p-0">{contacts.slice(0, SHOWN).map((contact, index) => contactRow(contact, index))}</ul>
            {contacts.length > SHOWN ? (
              <details>
                <summary className="cursor-pointer text-sm font-semibold text-link">{format(text.moreContacts, { n: contacts.length - SHOWN })}</summary>
                <ul className="m-0 mt-3 flex list-none flex-col gap-3 p-0">
                  {contacts.slice(SHOWN).map((contact, index) => contactRow(contact, index + SHOWN))}
                </ul>
              </details>
            ) : null}
          </div>
        )}
      </section>

      <fieldset className="m-0 flex flex-col gap-2 border-0 p-0">
        <legend className="mb-1 text-base font-bold">{text.about}</legend>
        <p className="m-0 mb-1 text-sm text-muted">{text.aboutHint}</p>
        {signals.map((s) => (
          <Checkbox
            key={s.signal}
            name="about"
            value={s.signal}
            checked={chosen.has(s.signal)}
            onChange={(event) => toggle(s.signal, event.currentTarget.checked)}
            label={titles[s.signal] ?? s.signal}
            hint={snoozed[s.signal] ? format(text.paused, { date: snoozed[s.signal] }) : undefined}
          />
        ))}
      </fieldset>

      <div className="flex flex-col gap-2">
        <p className="m-0 text-sm font-semibold" id="reach-language">
          {text.language}
        </p>
        <div role="group" aria-labelledby="reach-language" className="flex gap-1.5">
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
      </div>

      <Textarea
        id="reach-message"
        label={text.messageLabel}
        icon={Message01Icon}
        rows={10}
        value={body}
        onChange={(event) => setEdited({ key, body: event.currentTarget.value, notice })}
      />

      <div className="grid gap-4 sm:grid-cols-2">
        <Select
          id="reach-snooze"
          label={text.snooze}
          icon={PauseIcon}
          value={snooze}
          onChange={setSnooze}
          options={SNOOZE_DAYS.map((d) => ({ value: String(d), label: text.snoozeOptions[String(d) as keyof typeof text.snoozeOptions] }))}
        />
        <DatePicker
          id="reach-follow-up"
          label={text.followUp}
          hint={text.followUpHint}
          value={followUp}
          onChange={setFollowUp}
          min={today}
          locale={language}
          text={dateText}
        />
      </div>

      <form action={props.sendNotice} className="flex flex-col gap-3 rounded-md bg-surface-2/60 p-4">
        {shared}
        <input type="hidden" name="link" value={ready.link ?? ""} />
        <Textarea
          id="reach-notice"
          name="notice"
          label={text.sendNotice}
          icon={Megaphone01Icon}
          hint={text.noticeHint}
          rows={4}
          maxLength={600}
          value={notice}
          onChange={(event) => setEdited({ key, body, notice: event.currentTarget.value })}
        />
        <div>
          <Button type="submit" icon={Megaphone01Icon}>
            {text.sendNotice}
          </Button>
        </div>
      </form>

      <form action={props.logOutreach} className="flex flex-col gap-3 rounded-md bg-surface-2/60 p-4">
        {shared}
        <div>
          <p className="m-0 text-base font-bold">{text.log}</p>
          <p className="m-0 text-sm text-muted">{text.logHint}</p>
        </div>
        <Select
          id="reach-channel"
          name="channel"
          label={text.channel}
          icon={Calendar02Icon}
          defaultValue="email"
          options={CHANNELS.filter((c) => c !== "notice").map((c) => ({ value: c, label: text.channels[c] }))}
        />
        <Textarea id="reach-note" name="note" label={text.note} icon={NoteEditIcon} placeholder={text.notePlaceholder} rows={3} maxLength={1000} />
        <div>
          <Button type="submit" variant="secondary" icon={NoteEditIcon}>
            {text.save}
          </Button>
        </div>
      </form>
    </div>
  );
}
