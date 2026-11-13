import { DownloadCircle01Icon, FileAttachmentIcon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";

/**
 * The two ways to take the styleguide away: a Markdown file written for AI agents, and a PDF for reading and printing.
 * Both are built from the same content as this page (lib/styleguide/content.ts), by admin-only routes.
 */
export function ExportLinks() {
  return (
    <div className="flex flex-wrap gap-2" role="group" aria-label="Export the styleguide">
      <ButtonLink href="/styleguide/export/markdown" variant="secondary" icon={DownloadCircle01Icon} download tip="A Markdown file to give an AI agent">
        Markdown for agents
      </ButtonLink>
      <ButtonLink href="/styleguide/export/pdf" variant="secondary" icon={FileAttachmentIcon} download tip="A PDF to read or print">
        PDF
      </ButtonLink>
    </div>
  );
}
