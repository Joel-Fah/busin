import type { Metadata } from "next";
import { Download04Icon } from "@hugeicons/core-free-icons";
import Link from "next/link";
import { Suspense } from "react";

import { InvoicePay } from "@/components/payments/InvoicePay";
import { PayoutAccount } from "@/components/payments/PayoutAccount";
import { RefundDecision } from "@/components/payments/RefundDecision";
import { Avatar } from "@/components/ui/Avatar";
import { BackLink } from "@/components/ui/BackLink";
import { BarTable } from "@/components/ui/BarTable";
import { ButtonLink } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { Pager } from "@/components/ui/Pager";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";
import { Tabs, type TabItem } from "@/components/ui/Tabs";
import { requireAdmin } from "@/lib/auth";
import { formatAmount } from "@/lib/billing";
import { format } from "@/lib/i18n/messages";
import { paymentsCatalogues } from "@/lib/i18n/payments";
import { getMessages } from "@/lib/i18n/server";
import { PAGE_SIZES, lastPage, pageRange, parsePage } from "@/lib/pagination";
import {
  OPEN_PAYMENT_STATUSES,
  PAYMENT_FILTERS,
  TAKEN_REFUND_STATUSES,
  isProvider,
  maskPhone,
  monthColumns,
  parsePaymentsQuery,
  parseSummary,
  paymentStage,
  paymentsHref,
  payoutGroup,
  payoutReadiness,
  refundGroup,
  refundTone,
  showMasked,
  stageTone,
  type PaymentFilter,
} from "@/lib/payments";
import { createClient } from "@/lib/supabase/server";

import { confirmPayoutAccount, decideRefund, declinePayoutAccount, invoicePaymentState, proposePayoutAccount, startInvoicePayment } from "./actions";

export const metadata: Metadata = { title: "Payments" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type SearchParams = Promise<{ status?: string | string[]; page?: string | string[]; size?: string | string[] }>;

export default function PaymentsPage({ searchParams }: { searchParams: SearchParams }) {
  return (
    <Suspense fallback={<ListSkeleton rows={4} />}>
      <Payments searchParams={searchParams} />
    </Suspense>
  );
}

const PAYMENT_COLUMNS =
  "id, purpose, subscription_id, amount_xaf, fee_xaf, total_xaf, provider, status, receipt_no, outcome, created_at, completed_at, " +
  "payer:profiles!payments_paid_by_fkey(full_name, email, matricule), part:subscription_installments!payments_installment_id_fkey(seq), " +
  "invoice:busin_invoices!payments_invoice_id_fkey(number), refunds(status)";

/** The school's payments (ADR 0029): balance, payouts, refunds to decide, the payments list, the payout number and BusIn's invoices. */
async function Payments({ searchParams }: { searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const p = paymentsCatalogues[locale];
  const query = await searchParams;
  const filters = parsePaymentsQuery(query);
  const page = parsePage(query.page);
  const size = filters.size ?? 20;
  const { from, to } = pageRange(page, size);
  const supabase = await createClient();

  // Each status group narrows the same way for the list and for the numbers on its tab.
  const narrow = <Q extends { in(c: string, v: readonly string[]): Q; eq(c: string, v: string): Q; is(c: string, v: null): Q }>(q: Q, status: PaymentFilter): Q => {
    if (status === "waiting") return q.in("status", OPEN_PAYMENT_STATUSES);
    if (status === "failed") return q.eq("status", "failed");
    if (status === "refunded") return q.in("taken.status", TAKEN_REFUND_STATUSES);
    if (status === "paid") return q.eq("status", "completed").eq("outcome", "applied").in("taken.status", TAKEN_REFUND_STATUSES).is("taken", null);
    return q;
  };
  const takenJoin = (status: PaymentFilter) => (status === "refunded" ? "taken:refunds!inner(status)" : status === "paid" ? "taken:refunds(status)" : null);
  const listColumns = [PAYMENT_COLUMNS, takenJoin(filters.status)].filter(Boolean).join(", ");

  const [summaryRes, activeRes, proposalRes, adminsRes, requestedRes, recentRes, listRes, payoutsRes, invoicesRes, ...countRes] = await Promise.all([
    supabase.rpc("admin_payment_summary", { p_months: 6 }),
    supabase.from("school_payout_accounts").select("provider, phone, account_name, confirmed_at, usable_from").eq("status", "active").maybeSingle(),
    supabase
      .from("school_payout_accounts")
      .select("id, provider, phone, account_name, proposed_by, proposed_at, proposer:profiles!school_payout_accounts_proposed_by_fkey(full_name, email)")
      .eq("status", "proposed")
      .maybeSingle(),
    supabase.from("profiles").select("id", { count: "exact", head: true }).eq("role", "admin").eq("status", "verified"),
    supabase
      .from("refunds")
      .select("id, amount_xaf, reason, requested_at, student:profiles!refunds_student_id_fkey(full_name, email, matricule), payment:payments!refunds_payment_id_fkey(amount_xaf, receipt_no)")
      .eq("status", "requested")
      .order("requested_at", { ascending: true })
      .limit(50),
    supabase
      .from("refunds")
      .select("id, kind, amount_xaf, status, requested_at, decided_at, completed_at, receipt_no, student:profiles!refunds_student_id_fkey(full_name, email)")
      .neq("status", "requested")
      .order("requested_at", { ascending: false })
      .limit(10),
    narrow(supabase.from("payments").select(listColumns, { count: "exact" }), filters.status)
      .order("created_at", { ascending: false })
      .range(from, to),
    supabase.from("payouts").select("id, amount_xaf, provider, phone_masked, status, created_at, completed_at").order("created_at", { ascending: false }).limit(12),
    supabase.from("busin_invoices").select("id, number, month, amount_xaf, status, issued_at, due_date, paid_at").order("issued_at", { ascending: false }).limit(12),
    ...PAYMENT_FILTERS.map((status) =>
      narrow(supabase.from("payments").select(["id", takenJoin(status)].filter(Boolean).join(", "), { count: "exact", head: true }), status),
    ),
  ]);

  if (summaryRes.error) {
    return (
      <>
        <PageHeader title={p.page.title} subtitle={p.page.subtitle} />
        <Notice tone="bad">{p.page.loadError}</Notice>
      </>
    );
  }

  const summary = parseSummary(summaryRes.data);
  const money = (n: number) => formatAmount(n, locale);
  const dateTime = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeStyle: "short", timeZone: admin.schoolTimezone }).format(new Date(iso));
  const date = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: admin.schoolTimezone }).format(new Date(iso));
  const day = (iso: string) => new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: "UTC" }).format(new Date(`${iso.slice(0, 10)}T00:00:00Z`));
  const longDay = (iso: string) => new Intl.DateTimeFormat(locale, { day: "numeric", month: "long", timeZone: "UTC" }).format(new Date(`${iso.slice(0, 10)}T00:00:00Z`));
  const monthName = (iso: string) => new Intl.DateTimeFormat(locale, { month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${iso.slice(0, 10)}T00:00:00Z`));
  const operator = (provider: string) => (isProvider(provider) ? p.operators[provider] : provider);
  const nameOf = (person: { full_name: string | null; email: string | null } | null) => person?.full_name || person?.email || p.list.noName;
  const reasonText = { presetsLabel: t.reasons.presetsLabel, counter: t.reasons.counter, minimum: t.reasons.minimum };

  const proposal = proposalRes.data;
  const active = activeRes.data;
  const now = new Date();
  const readiness = payoutReadiness(summary, Boolean(proposal), now);
  const readinessText = (() => {
    switch (readiness.kind) {
      case "off":
        return p.readiness.off;
      case "noNumber":
        return p.readiness.noNumber;
      case "waitingConfirmation":
        return p.readiness.waitingConfirmation;
      case "usableFrom":
        return format(p.readiness.usableFrom, { date: date(readiness.date) });
      case "belowMin":
        return format(p.readiness.belowMin, { min: money(readiness.min), available: money(readiness.available) });
      case "ready":
        return format(p.readiness.ready, { date: longDay(readiness.day), amount: money(readiness.amount), operator: operator(readiness.provider), phone: showMasked(readiness.phone) });
    }
  })();

  // The open invoice: what paying it by mobile money comes to, and a payment of it still going.
  const invoice = summary.openInvoice;
  const [quoteRes, openPaymentRes] = invoice
    ? await Promise.all([
        supabase.rpc("payment_quote", { p_purpose: "invoice", p_target: invoice.id }),
        supabase.from("payments").select("id, total_xaf").eq("invoice_id", invoice.id).in("status", OPEN_PAYMENT_STATUSES).order("created_at", { ascending: false }).limit(1).maybeSingle(),
      ])
    : [null, null];

  // A page past the last one is simply empty.
  const outOfRange = listRes.error?.code === "PGRST103";
  const listError = outOfRange ? null : listRes.error;
  const rows = (listRes.data ?? []) as unknown as PaymentRow[];
  const total = listRes.count ?? 0;
  const tabs: TabItem[] = PAYMENT_FILTERS.map((status, index) => ({
    id: status,
    label: p.list.filters[status],
    href: paymentsHref({ ...filters, status }),
    count: countRes[index].count ?? 0,
    tone: status === "all" ? "neutral" : status === "waiting" ? "warn" : status === "failed" ? "bad" : status === "refunded" ? "info" : "ok",
  }));

  const columns = monthColumns(summary.months, summary.feesPaidBy);
  const thisMonth = summary.months.at(-1)?.month;
  const anyMonth = summary.months.some((m) => columns.some((c) => m[c] !== 0));
  const requested = requestedRes.data ?? [];
  const recent = recentRes.data ?? [];

  return (
    <>
      <BackLink href="/profile">{p.page.back}</BackLink>
      <PageHeader
        title={p.page.title}
        subtitle={p.page.subtitle}
        action={
          <ButtonLink href="/payments/export" variant="secondary" icon={Download04Icon} download tip={p.page.exportHint}>
            {p.page.export}
          </ButtonLink>
        }
      />

      {summary.mobileMoney ? null : <Notice tone="info">{p.page.mobileMoneyOff}</Notice>}

      <section aria-label={p.tiles.label} className="grid grid-cols-[minmax(0,1fr)] gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <MoneyTile testId="tile-available" label={p.tiles.available} value={money(summary.balance.available)} hint={p.tiles.availableHint} />
        <MoneyTile testId="tile-on-hold" label={p.tiles.onHold} value={money(summary.balance.onHold)} hint={format(p.tiles.onHoldHint, { days: summary.holdDays })} />
        {summary.balance.owed > 0 ? <MoneyTile testId="tile-owed" label={p.tiles.owed} value={money(summary.balance.owed)} hint={p.tiles.owedHint} tone="warn" /> : null}
        <Card className="flex min-h-40 flex-col gap-3 p-7!">
          <div data-testid="tile-payout" className="flex flex-col gap-3">
            <span className="flex items-center justify-between gap-3">
              <span className="text-sm font-semibold text-muted">{p.tiles.payout}</span>
              <Chip tone={readiness.kind === "ready" ? "ok" : "warn"}>{readiness.kind === "ready" ? p.readiness.scheduled : p.readiness.waiting}</Chip>
            </span>
            <p className="m-0 text-base font-semibold">{readinessText}</p>
            {readiness.kind === "ready" ? <p className="m-0 text-sm text-muted">{p.readiness.readyHint}</p> : null}
          </div>
        </Card>
      </section>

      {requested.length > 0 ? (
        <section aria-labelledby="refunds-to-decide" className="flex flex-col gap-3" data-testid="refunds-to-decide">
          <div>
            <h2 id="refunds-to-decide" className="text-2xl font-bold">
              {p.refunds.title}
            </h2>
            <p className="mt-1 text-sm text-muted">{p.refunds.hint}</p>
          </div>
          <ul className="m-0 grid list-none gap-3 p-0">
            {requested.map((r) => {
              const name = nameOf(r.student);
              const paid = r.payment?.amount_xaf ?? r.amount_xaf;
              return (
                <li key={r.id} className="flex flex-wrap items-center gap-4 rounded-lg bg-surface p-5 shadow-soft">
                  <Avatar name={name} url={null} size={40} />
                  <div className="min-w-48 flex-1">
                    <p className="m-0 font-semibold">{name}</p>
                    <p className="m-0 text-sm text-muted">
                      {money(paid)} · {format(p.refunds.askedOn, { date: dateTime(r.requested_at) })}
                    </p>
                    {r.reason ? <p className="m-0 mt-1 text-sm">{r.reason}</p> : null}
                  </div>
                  <RefundDecision
                    refund={{ id: r.id, studentName: name, amount: paid, amountText: money(paid), reason: r.reason, asked: dateTime(r.requested_at), receipt: r.payment?.receipt_no ?? null }}
                    copy={p.refunds}
                    errors={p.errors}
                    reasonText={reasonText}
                    action={decideRefund}
                  />
                </li>
              );
            })}
          </ul>
        </section>
      ) : null}

      <section aria-labelledby="months" className="flex flex-col gap-3">
        <div>
          <h2 id="months" className="text-2xl font-bold">
            {p.months.title}
          </h2>
          <p className="mt-1 max-w-3xl text-sm text-muted">{p.months.hint}</p>
        </div>
        {anyMonth ? (
          <div data-testid="months">
            <BarTable
              caption={p.months.caption}
              rowHeading={p.months.month}
              columns={columns.map((c) => ({ key: c, label: p.months.columns[c] }))}
              highlight={thisMonth ? { key: thisMonth, label: p.months.thisMonth } : undefined}
              rows={[...summary.months].reverse().map((m) => ({
                key: m.month,
                label: monthName(m.month),
                values: Object.fromEntries(columns.map((c) => [c, m[c]])),
                display: Object.fromEntries(columns.map((c) => [c, money(m[c])])),
              }))}
            />
          </div>
        ) : (
          <p className="m-0 rounded-md bg-surface-2 px-5 py-4 text-sm text-muted">{p.months.empty}</p>
        )}
      </section>

      <section id="payments-list" aria-labelledby="payments-title" className="flex scroll-mt-6 flex-col gap-3">
        <div>
          <h2 id="payments-title" className="text-2xl font-bold">
            {p.list.title}
          </h2>
          <p className="mt-1 text-sm text-muted">{p.list.hint}</p>
        </div>
        <Tabs label={p.list.filtersLabel} items={tabs} active={filters.status} />
        {listError ? (
          <Notice tone="bad">{p.page.loadError}</Notice>
        ) : rows.length === 0 ? (
          <p className="m-0 rounded-md bg-surface-2 px-5 py-4 text-sm text-muted">{filters.status === "all" ? p.list.empty : p.list.emptyFiltered}</p>
        ) : (
          <>
            <TableCard>
              <DataTable minWidth="60rem">
                <Head>
                  <Th>{p.list.columns.student}</Th>
                  <Th>{p.list.columns.what}</Th>
                  <Th className="text-right">{p.list.columns.amount}</Th>
                  <Th className="text-right">{p.list.columns.fee}</Th>
                  <Th className="text-right">{p.list.columns.total}</Th>
                  <Th>{p.list.columns.operator}</Th>
                  <Th>{p.list.columns.receipt}</Th>
                  <Th>{p.list.columns.date}</Th>
                  <Th>{p.list.columns.status}</Th>
                </Head>
                <tbody>
                  {rows.map((row) => {
                    const stage = paymentStage(row, row.refunds ?? []);
                    const what =
                      row.purpose === "invoice"
                        ? format(p.list.invoice, { number: row.invoice?.number ?? "" })
                        : row.purpose === "installment"
                          ? format(p.list.part, { n: row.part?.seq ?? "" })
                          : p.list.request;
                    return (
                      <Tr key={row.id}>
                        <Td>
                          <span className="font-semibold">{nameOf(row.payer)}</span>
                          {row.payer?.matricule ? <span className="block text-xs text-muted">{row.payer.matricule}</span> : null}
                        </Td>
                        <Td>
                          {row.subscription_id ? (
                            <Link href={`/subscriptions/${row.subscription_id}?past=1`} className="font-semibold no-underline">
                              {what}
                            </Link>
                          ) : (
                            what
                          )}
                        </Td>
                        <Td className="text-right whitespace-nowrap tabular-nums">{money(row.amount_xaf)}</Td>
                        <Td className="text-right whitespace-nowrap tabular-nums text-muted">{money(row.fee_xaf)}</Td>
                        <Td className="text-right font-semibold whitespace-nowrap tabular-nums">{money(row.total_xaf)}</Td>
                        <Td>{operator(row.provider)}</Td>
                        <Td className="whitespace-nowrap tabular-nums">{row.receipt_no ?? "-"}</Td>
                        <Td className="whitespace-nowrap text-muted">{dateTime(row.completed_at ?? row.created_at)}</Td>
                        <Td>
                          <Chip tone={stageTone(stage)}>{p.list.filters[stage]}</Chip>
                        </Td>
                      </Tr>
                    );
                  })}
                </tbody>
              </DataTable>
            </TableCard>
            <Pager
              range={format(p.list.range, { from: from + 1, to: from + rows.length, total })}
              label={p.list.paginationLabel}
              previous={page > 1 ? { href: paymentsHref(filters, page - 1), label: p.list.previous } : undefined}
              next={page < lastPage(total, size) ? { href: paymentsHref(filters, page + 1), label: p.list.next } : undefined}
              perPage={{
                label: t.pager.perPage,
                groupLabel: t.pager.perPageLabel,
                current: size,
                options: PAGE_SIZES.map((n) => ({ size: n, href: paymentsHref({ ...filters, size: n }) })),
              }}
            />
          </>
        )}
      </section>

      <div className="grid gap-6 lg:grid-cols-2">
        <PayoutAccount
          active={
            active
              ? {
                  provider: active.provider,
                  phone: maskPhone(active.phone),
                  name: active.account_name,
                  since: date(active.usable_from ?? active.confirmed_at ?? now.toISOString()),
                  later: Boolean(active.usable_from && Date.parse(active.usable_from) > now.getTime()),
                }
              : null
          }
          proposal={
            proposal
              ? {
                  id: proposal.id,
                  provider: proposal.provider,
                  phone: maskPhone(proposal.phone),
                  name: proposal.account_name,
                  by: nameOf(proposal.proposer),
                  at: date(proposal.proposed_at),
                  mine: proposal.proposed_by === admin.userId,
                }
              : null
          }
          soleAdmin={(adminsRes.count ?? 0) <= 1}
          copy={p.account}
          operators={p.operators}
          errors={p.errors}
          actions={{ propose: proposePayoutAccount, confirm: confirmPayoutAccount, decline: declinePayoutAccount }}
        />

        <Card className="flex flex-col gap-5">
          <div data-testid="invoices" className="flex flex-col gap-5">
            <div>
              <h2 className="text-xl font-bold">{p.invoices.title}</h2>
              <p className="mt-1 text-sm text-muted">{p.invoices.hint}</p>
            </div>
            {invoice ? (
              <>
                <Notice tone="warn">{format(p.invoices.open, { number: invoice.number, amount: money(invoice.amount), date: day(invoice.dueDate) })}</Notice>
                <InvoicePay
                  invoice={{ id: invoice.id }}
                  quote={(quoteRes?.data ?? []).map((q) => ({ provider: q.provider, amount: q.amount_xaf, fee: q.fee_xaf, total: q.total_xaf }))}
                  pending={openPaymentRes?.data ? { id: openPaymentRes.data.id, total: openPaymentRes.data.total_xaf ?? 0 } : null}
                  locale={locale}
                  copy={p.pay}
                  operators={p.operators}
                  start={startInvoicePayment}
                  check={invoicePaymentState}
                />
              </>
            ) : null}
            {(invoicesRes.data ?? []).length === 0 ? (
              <p className="m-0 text-sm text-muted">{p.invoices.none}</p>
            ) : (
              <ul className="m-0 flex list-none flex-col gap-2 p-0">
                {(invoicesRes.data ?? []).map((i) => (
                  <li key={i.id} className="flex flex-wrap items-center justify-between gap-2 rounded-md bg-surface-2 px-4 py-3 text-sm">
                    <span>
                      <span className="font-semibold tabular-nums">{i.number}</span>
                      <span className="ml-2 text-muted capitalize">{monthName(i.month)}</span>
                    </span>
                    <span className="flex items-center gap-3">
                      <span className="font-semibold tabular-nums">{money(i.amount_xaf)}</span>
                      <Chip tone={i.status === "paid" ? "ok" : i.status === "open" ? "warn" : "neutral"}>
                        {p.invoices.statuses[i.status as keyof typeof p.invoices.statuses] ?? i.status}
                      </Chip>
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="flex flex-col gap-4">
          <div data-testid="payouts" className="flex flex-col gap-4">
            <div>
              <h2 className="text-xl font-bold">{p.payouts.title}</h2>
              <p className="mt-1 text-sm text-muted">{p.payouts.hint}</p>
            </div>
            {(payoutsRes.data ?? []).length === 0 ? (
              <p className="m-0 text-sm text-muted">{p.payouts.none}</p>
            ) : (
              <ul className="m-0 flex list-none flex-col gap-2 p-0">
                {(payoutsRes.data ?? []).map((o) => {
                  const group = payoutGroup(o.status);
                  return (
                    <li key={o.id} className="flex flex-wrap items-center justify-between gap-2 rounded-md bg-surface-2 px-4 py-3 text-sm">
                      <span>
                        <span className="font-semibold">{date(o.completed_at ?? o.created_at)}</span>
                        <span className="ml-2 text-muted">
                          {operator(o.provider)} {showMasked(o.phone_masked)}
                        </span>
                      </span>
                      <span className="flex items-center gap-3">
                        <span className="font-semibold tabular-nums">{money(o.amount_xaf)}</span>
                        <Chip tone={group === "sent" ? "ok" : group === "failed" ? "bad" : "info"}>{p.payouts.statuses[group]}</Chip>
                      </span>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </Card>

        <Card className="flex flex-col gap-4">
          <div data-testid="recent-refunds" className="flex flex-col gap-4">
            <div>
              <h2 className="text-xl font-bold">{p.refunds.recentTitle}</h2>
              <p className="mt-1 text-sm text-muted">{p.refunds.recentHint}</p>
            </div>
            {recent.length === 0 ? (
              <p className="m-0 text-sm text-muted">{requested.length > 0 ? p.refunds.recentNone : p.refunds.none}</p>
            ) : (
              <ul className="m-0 flex list-none flex-col gap-2 p-0">
                {recent.map((r) => {
                  const group = refundGroup(r.status);
                  return (
                    <li key={r.id} className="flex flex-wrap items-center justify-between gap-2 rounded-md bg-surface-2 px-4 py-3 text-sm">
                      <span className="min-w-0">
                        <span className="font-semibold">{nameOf(r.student)}</span>
                        <span className="ml-2 text-muted">
                          {p.refunds.kinds[r.kind as keyof typeof p.refunds.kinds] ?? r.kind} · {date(r.completed_at ?? r.decided_at ?? r.requested_at)}
                        </span>
                      </span>
                      <span className="flex items-center gap-3">
                        <span className="font-semibold tabular-nums">{money(r.amount_xaf)}</span>
                        <Chip tone={refundTone(group)}>{p.refunds.statuses[group]}</Chip>
                      </span>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </Card>
      </div>

      <p className="text-sm text-muted">
        <Link href="/billing" className="font-semibold no-underline">
          {p.page.billingLink}
        </Link>
      </p>
    </>
  );
}

type PaymentRow = {
  id: string;
  purpose: string;
  subscription_id: string | null;
  amount_xaf: number;
  fee_xaf: number;
  total_xaf: number;
  provider: string;
  status: string;
  receipt_no: string | null;
  outcome: string | null;
  created_at: string;
  completed_at: string | null;
  payer: { full_name: string | null; email: string | null; matricule: string | null } | null;
  part: { seq: number } | null;
  invoice: { number: string } | null;
  refunds: { status: string }[] | null;
};

/** A figure of the balance: a quiet label, a large amount, and what it means. */
function MoneyTile({ label, value, hint, tone, testId }: { label: string; value: string; hint: string; tone?: "warn"; testId: string }) {
  return (
    <Card className={`flex min-h-40 flex-col justify-between gap-3 p-7! ${tone === "warn" ? "bg-warn-bg!" : ""}`}>
      <div data-testid={testId} className="flex flex-1 flex-col justify-between gap-3">
        <span className="text-sm font-semibold text-muted">{label}</span>
        <span className="text-3xl font-extrabold tracking-tight tabular-nums sm:text-4xl">{value}</span>
        <span className="text-sm text-muted">{hint}</span>
      </div>
    </Card>
  );
}
