import { requireAdmin } from "@/lib/auth";
import { buildPdf } from "@/lib/styleguide/pdf";

/** The styleguide as a PDF for reading and printing (administrators only, like the page). */
export async function GET() {
  await requireAdmin();
  const generatedOn = new Date().toISOString().slice(0, 10);
  const pdf = await buildPdf({ generatedOn });
  return new Response(new Uint8Array(pdf), {
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": 'attachment; filename="busin-design-system.pdf"',
      "Cache-Control": "private, no-store",
    },
  });
}
