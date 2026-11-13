import { requireAdmin } from "@/lib/auth";
import { buildMarkdown } from "@/lib/styleguide/markdown";

/** The styleguide as a Markdown file for AI agents (administrators only, like the page). */
export async function GET() {
  await requireAdmin();
  const generatedOn = new Date().toISOString().slice(0, 10);
  return new Response(buildMarkdown({ generatedOn }), {
    headers: {
      "Content-Type": "text/markdown; charset=utf-8",
      "Content-Disposition": 'attachment; filename="busin-design-system.md"',
      "Cache-Control": "private, no-store",
    },
  });
}
