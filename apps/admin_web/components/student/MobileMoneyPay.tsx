"use client";

import { Alert02Icon, CancelCircleIcon, CheckmarkCircle02Icon, Loading03Icon, RefreshIcon, SmartPhone01Icon } from "@hugeicons/core-free-icons";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Notice } from "@/components/ui/Notice";
import { useToast } from "@/components/ui/Toast";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import {
  PAYMENT_COLUMNS,
  failureReason,
  isProvider,
  linesFromQuote,
  maskedDisplay,
  normalizeCameroonPhone,
  stageOfPayment,
  type PaymentRow,
  type PriceLines,
  type Provider,
  type QuoteRow,
  type StartError,
} from "@/lib/student/mobile-money";
import { checkMobileMoneyPayment, startMobileMoneyPayment } from "@/lib/student/payments";
import { browserClient } from "@/lib/supabase/browser";

import { MobileMoneyNumber, PriceSummary, effectiveOperator } from "./MobileMoneyFields";

type PayCopy = StudentCopy["subscription"]["pay"];
type Payment = Pick<PaymentRow, "id" | "status" | "failure_code" | "total_xaf" | "provider" | "payer_masked" | "outcome">;

const POLL_MS = 10_000;

/** A quote's refusal (the database's short reason) as one of the messages the app has. */
function quoteError(message: string | undefined): StartError | "quote" {
  const code = message ?? "";
  for (const known of ["mobile_money_off", "not_payable", "period_ended", "not_found", "not_allowed"] as const) if (code.includes(known)) return known;
  return "quote";
}

/**
 * Follows one payment while the page is open: Realtime on its own row (RLS lets the student read only theirs), and a
 * read every ten seconds in case the channel drops, both only while the tab is visible. Reads the row again rather than
 * trusting the event, with named columns only.
 */
function useFollowPayment(id: string | null, open: boolean, onRow: (row: Payment) => void) {
  const latest = useRef(onRow);
  useEffect(() => {
    latest.current = onRow;
  }, [onRow]);

  useEffect(() => {
    if (!id || !open) return;
    const supabase = browserClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;
    let timer: ReturnType<typeof setInterval> | null = null;
    let stopped = false;

    const read = async () => {
      const { data } = await supabase.from("payments").select(PAYMENT_COLUMNS).eq("id", id).maybeSingle();
      if (!stopped && data) latest.current(data as unknown as Payment);
    };
    const start = async () => {
      if (!timer) timer = setInterval(() => void read(), POLL_MS);
      if (channel) return;
      // The channel carries the student's token, or RLS shows it nothing (as LiveSubscriptions).
      const { data } = await supabase.auth.getSession();
      if (stopped || channel || !data.session) return;
      await supabase.realtime.setAuth(data.session.access_token);
      if (stopped || channel) return;
      channel = supabase
        .channel(`payment:${id}`)
        .on("postgres_changes", { event: "UPDATE", schema: "public", table: "payments", filter: `id=eq.${id}` }, () => void read())
        .subscribe();
    };
    const stop = () => {
      if (timer) clearInterval(timer);
      timer = null;
      if (channel) void supabase.removeChannel(channel);
      channel = null;
    };
    const onVisibility = () => {
      if (document.visibilityState === "visible") {
        void read();
        void start();
      } else stop();
    };

    if (document.visibilityState === "visible") void start();
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      stopped = true;
      document.removeEventListener("visibilitychange", onVisibility);
      stop();
    };
  }, [id, open]);
}

/**
 * Paying one item by mobile money (ADR 0029): a pending request ("subscription") or a later part ("installment").
 * With no payment yet, or after one failed: the number, its network, what it comes to, and Pay. While pawaPay waits for
 * the student's PIN: what to do on the phone, followed live, with "check again". Then paid, refunded, or failed with the
 * reason in the student's words (nothing was taken). Starting and checking go through the server, never to pawaPay.
 */
export function MobileMoneyPay({
  copy,
  purpose,
  target,
  initialPayment,
  initialError = null,
  phone: initialPhone,
  operators,
  amountLabel,
  locale,
  currency,
  alternative = null,
  onCancel,
}: {
  copy: PayCopy;
  purpose: "subscription" | "installment";
  target: string;
  initialPayment: Payment | null;
  /** A refusal from starting just before this page loaded (the request form starts the first payment). */
  initialError?: StartError | null;
  /** The number to start with: the student's own, written the local way. */
  phone: string;
  operators: Provider[];
  amountLabel: string;
  locale: string;
  currency: string;
  /** Another way to pay (a receipt), offered when there is no payment in progress. */
  alternative?: ReactNode;
  /** Closes the form when it was opened from a button (a part), while nothing is in progress. */
  onCancel?: () => void;
}) {
  const router = useRouter();
  const toast = useToast();
  const [payment, setPayment] = useState<Payment | null>(initialPayment);
  const [retrying, setRetrying] = useState(false);
  const [error, setError] = useState<StartError | "quote" | null>(initialError);
  const [phone, setPhone] = useState(initialPhone);
  const [chosen, setChosen] = useState<Provider | null>(null);
  const [quote, setQuote] = useState<QuoteRow[] | null>(null);
  const [busy, setBusy] = useState<"start" | "check" | null>(null);
  const [notYet, setNotYet] = useState(false);
  const money = (n: number) => formatAmount(n, locale, currency);

  const stage = payment ? stageOfPayment(payment) : null;
  // Paying needs a network the school takes; without one only the other way (a receipt) is left.
  const canPay = operators.length > 0;
  const showForm = canPay && (!payment || (stage === "failed" && retrying));
  const waiting = stage === "waiting";

  // The status last shown, to act once on a change (a paid part is announced, the page read again).
  const shown = useRef(initialPayment?.status ?? null);
  const onRow = useCallback(
    (row: Payment) => {
      const before = shown.current;
      shown.current = row.status;
      setPayment(row);
      if (before === row.status) return;
      setNotYet(false);
      if (row.status === "completed") {
        // The request is approved by now (or the part paid): the page shows it. A request's approval is announced by the live feed.
        if (purpose === "installment") toast(copy.paidTitle, { tone: "ok" });
        router.refresh();
      }
    },
    [purpose, copy.paidTitle, router, toast],
  );
  useFollowPayment(payment?.id ?? null, waiting, onRow);

  // A refusal handed over in the address (from the request form) is shown once: the address is cleaned at once.
  useEffect(() => {
    if (!initialError) return;
    const url = new URL(window.location.href);
    if (!url.searchParams.has("pay_error")) return;
    url.searchParams.delete("pay_error");
    window.history.replaceState(window.history.state, "", url);
  }, [initialError]);

  // The price for this item, per network, when the form shows.
  useEffect(() => {
    if (!showForm || quote) return;
    let cancelled = false;
    void browserClient()
      .rpc("payment_quote", { p_purpose: purpose, p_target: target })
      .then(({ data, error: failed }) => {
        if (cancelled) return;
        if (failed) setError(quoteError(failed.message));
        else setQuote((data ?? []) as QuoteRow[]);
      });
    return () => {
      cancelled = true;
    };
  }, [showForm, quote, purpose, target]);

  const operator = effectiveOperator(phone, chosen);
  const lines: Partial<Record<Provider, PriceLines>> = {};
  for (const p of operators) {
    const l = linesFromQuote(quote, p);
    if (l) lines[p] = l;
  }
  const valid = normalizeCameroonPhone(phone) !== null;
  const priced = operator ? lines[operator] : undefined;
  const operatorOff = operator !== null && (!operators.includes(operator) || (quote !== null && !lines[operator]));

  const readRow = async (id: string) => {
    const { data } = await browserClient().from("payments").select(PAYMENT_COLUMNS).eq("id", id).maybeSingle();
    return data as unknown as Payment | null;
  };

  const pay = async () => {
    if (!valid || busy) return;
    if (!navigator.onLine) {
      setError("offline");
      return;
    }
    setBusy("start");
    setError(null);
    const result = await startMobileMoneyPayment({ purpose, target, phone, provider: chosen });
    if (!result.ok) {
      setBusy(null);
      setError(result.error);
      // Started meanwhile (another tab, another device): the page reads it and shows it.
      if (result.error === "payment_in_progress") router.refresh();
      return;
    }
    const row = (await readRow(result.payment.paymentId)) ?? {
      id: result.payment.paymentId,
      status: result.payment.status,
      failure_code: result.payment.failureCode,
      total_xaf: result.payment.total,
      provider: result.payment.provider,
      payer_masked: "",
      outcome: null,
    };
    setBusy(null);
    setRetrying(false);
    onRow(row);
  };

  const check = async () => {
    if (!payment || busy) return;
    setBusy("check");
    setError(null);
    const result = await checkMobileMoneyPayment(payment.id);
    const row = await readRow(payment.id);
    setBusy(null);
    if (!result.ok) setError(result.error);
    if (row) {
      onRow(row);
      setNotYet(stageOfPayment(row) === "waiting");
    }
  };

  const operatorName = (p: string) => (isProvider(p) ? copy.operators[p] : p);
  const errorText = error === "quote" ? copy.quoteFailed : error ? copy.errors[error] : null;

  return (
    <div className="flex flex-col gap-3" data-testid={`momo-${purpose}`}>
      {/* Every change of state is said once, politely, to screen readers. */}
      <p className="sr-only" role="status" aria-live="polite">
        {stage === "waiting" ? copy.waitingTitle : stage === "checking" ? copy.attentionTitle : stage === "paid" ? copy.paidTitle : stage === "refunded" ? copy.refunding : stage === "failed" ? copy.failedTitle : ""}
      </p>

      {payment && stage === "waiting" ? (
        <div className="flex flex-col gap-3 rounded-md bg-info-bg p-4" data-testid="momo-waiting">
          <p className="m-0 flex items-center gap-2 font-bold text-info">
            <Icon icon={SmartPhone01Icon} size={20} />
            {copy.waitingTitle}
          </p>
          <p className="m-0 text-sm text-fg">{format(copy.waitingBody, { total: money(payment.total_xaf), operator: operatorName(payment.provider) })}</p>
          {payment.payer_masked ? <p className="m-0 text-sm text-muted">{format(copy.waitingNumber, { number: maskedDisplay(payment.payer_masked) })}</p> : null}
          <p className="m-0 flex items-center gap-2 text-sm text-muted">
            <Icon icon={Loading03Icon} size={16} className="animate-spin motion-reduce:animate-none" />
            {notYet ? copy.notYet : copy.checking}
          </p>
          <Button variant="secondary" icon={RefreshIcon} disabled={busy !== null} onClick={check}>
            {busy === "check" ? copy.checking : copy.checkAgain}
          </Button>
        </div>
      ) : null}

      {payment && stage === "checking" ? (
        <div className="flex flex-col gap-1 rounded-md bg-warn-bg p-4" data-testid="momo-checking">
          <p className="m-0 flex items-center gap-2 font-bold text-warn">
            <Icon icon={Alert02Icon} size={20} />
            {copy.attentionTitle}
          </p>
          <p className="m-0 text-sm text-fg">{copy.attentionBody}</p>
        </div>
      ) : null}

      {payment && stage === "paid" ? (
        <p className="m-0 flex items-center gap-2 rounded-md bg-ok-bg p-4 font-bold text-ok" data-testid="momo-paid">
          <Icon icon={CheckmarkCircle02Icon} size={20} />
          {copy.paidTitle}
        </p>
      ) : null}

      {payment && stage === "refunded" ? (
        <p className="m-0 flex items-center gap-2 rounded-md bg-warn-bg p-4 font-bold text-warn" data-testid="momo-refunded">
          <Icon icon={Alert02Icon} size={20} />
          {copy.refunding}
        </p>
      ) : null}

      {payment && stage === "failed" && !retrying ? (
        <div className="flex flex-col gap-3 rounded-md bg-bad-bg p-4" data-testid="momo-failed">
          <p className="m-0 flex items-center gap-2 font-bold text-bad">
            <Icon icon={CancelCircleIcon} size={20} />
            {copy.failedTitle}
          </p>
          <p className="m-0 text-sm text-fg">{copy.reasons[failureReason(payment.failure_code)]}</p>
          <p className="m-0 text-sm font-semibold text-fg">{copy.nothingTaken}</p>
          {canPay ? (
            <Button
              onClick={() => {
                setRetrying(true);
                setError(null);
                setQuote(null);
              }}
            >
              {copy.tryAgain}
            </Button>
          ) : null}
        </div>
      ) : null}

      {showForm ? (
        <div className="flex flex-col gap-3" data-testid="momo-form">
          <h3 className="m-0 text-base font-bold">{payment ? copy.tryAgain : copy.payNow}</h3>
          <MobileMoneyNumber copy={copy} value={phone} onChange={setPhone} chosen={chosen} onChoose={setChosen} operators={operators} disabled={busy !== null} />
          {quote ? <PriceSummary copy={copy} amountLabel={amountLabel} operator={operator} lines={lines} locale={locale} currency={currency} /> : null}
          <Button className="h-14 w-full text-base" disabled={!valid || busy !== null || operatorOff} onClick={pay}>
            {busy === "start" ? copy.asking : priced ? format(copy.pay, { total: money(priced.total) }) : copy.payNow}
          </Button>
          {onCancel && !payment ? (
            <Button variant="ghost" className="h-11 w-full" disabled={busy !== null} onClick={onCancel}>
              {copy.cancel}
            </Button>
          ) : null}
        </div>
      ) : null}

      {errorText ? <Notice tone="bad">{errorText}</Notice> : null}

      {alternative && (!payment || stage === "failed") ? alternative : null}
    </div>
  );
}
