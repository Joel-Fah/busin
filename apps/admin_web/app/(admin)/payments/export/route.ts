import { requireAdmin } from "@/lib/auth";
import { paymentsCatalogues } from "@/lib/i18n/payments";
import { getLocale } from "@/lib/i18n/server";
import { CSV_BOM, csvRow, isLedgerKind, ledgerFileName } from "@/lib/payments";
import { createClient } from "@/lib/supabase/server";

/** Rows read from the database at a time while the file is written. */
const BATCH = 1000;
/** A safety cap on what one export reads (500,000 movements). */
const MAX_BATCHES = 500;

/**
 * The school's ledger as a CSV file for its accounts (ADR 0029): every movement of its balance, oldest first, with the
 * receipt numbers of the payment or refund behind it. Administrators only; Row Level Security limits the rows to their
 * school. Streamed in batches so a long history is never held in memory, with a byte order mark so Excel reads the
 * accents, and every cell escaped (quotes, commas, line breaks, and text that would run as a formula).
 */
export async function GET() {
  const admin = await requireAdmin();
  const locale = await getLocale();
  const copy = paymentsCatalogues[locale];
  const supabase = await createClient();
  const zone = admin.schoolTimezone;
  const at = (iso: string) => {
    // "2026-11-17 14:05" in the school's time, which sorts and reads the same in every spreadsheet.
    const parts = new Intl.DateTimeFormat("en-CA", { timeZone: zone, year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hourCycle: "h23" }).formatToParts(new Date(iso));
    const get = (type: string) => parts.find((p) => p.type === type)?.value ?? "";
    return `${get("year")}-${get("month")}-${get("day")} ${get("hour")}:${get("minute")}`;
  };
  const today = new Intl.DateTimeFormat("en-CA", { timeZone: zone }).format(new Date());

  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      controller.enqueue(encoder.encode(CSV_BOM + csvRow([copy.csv.date, copy.csv.kind, copy.csv.amount, copy.csv.available, copy.csv.paymentReceipt, copy.csv.refundReceipt, copy.csv.note])));
      // Keyset pagination on the identity: each batch starts after the last row written.
      let after = 0;
      for (let batch = 0; batch < MAX_BATCHES; batch++) {
        const { data, error } = await supabase
          .from("school_ledger")
          .select("id, kind, amount_xaf, available_at, note, created_at, payment:payments!school_ledger_payment_id_fkey(receipt_no), refund:refunds!school_ledger_refund_id_fkey(receipt_no)")
          .gt("id", after)
          .order("id", { ascending: true })
          .limit(BATCH);
        if (error) {
          controller.error(new Error("ledger_read_failed"));
          return;
        }
        for (const row of data ?? []) {
          controller.enqueue(
            encoder.encode(
              csvRow([
                at(row.created_at),
                isLedgerKind(row.kind) ? copy.ledgerKinds[row.kind] : row.kind,
                row.amount_xaf,
                at(row.available_at),
                row.payment?.receipt_no ?? "",
                row.refund?.receipt_no ?? "",
                row.note ?? "",
              ]),
            ),
          );
        }
        if (!data || data.length < BATCH) break;
        after = data[data.length - 1].id;
      }
      controller.close();
    },
  });

  const fileName = ledgerFileName(admin.schoolName, today);
  return new Response(stream, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="${fileName}"; filename*=UTF-8''${encodeURIComponent(fileName)}`,
      "Cache-Control": "private, no-store",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
