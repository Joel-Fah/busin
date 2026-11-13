"use client";

import { Search01Icon, School01Icon } from "@hugeicons/core-free-icons";
import { useActionState, useMemo, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { Modal } from "@/components/ui/Modal";
import { Notice } from "@/components/ui/Notice";
import { format } from "@/lib/i18n/format";
import type { StudentCopy } from "@/lib/i18n/student";
import { askToJoin, type JoinState } from "@/lib/student/onboarding";

export type OpenSchool = { id: string; name: string; place: string; logoUrl: string | null };

/** Lower case without accents, so "ecole" finds "École". */
function plain(text: string): string {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
}

/**
 * The schools that accept this student's email (ADR 0012), with a search by name or city. Choosing one asks to confirm,
 * then sends the request; the server decides the rest.
 */
export function SchoolChooser({ schools, copy }: { schools: OpenSchool[]; copy: StudentCopy["join"] }) {
  const [query, setQuery] = useState("");
  const [chosen, setChosen] = useState<OpenSchool | null>(null);
  const [state, action, pending] = useActionState<JoinState, FormData>(askToJoin, { error: null });

  const shown = useMemo(() => {
    const q = plain(query.trim());
    return q ? schools.filter((school) => plain(`${school.name} ${school.place}`).includes(q)) : schools;
  }, [query, schools]);

  return (
    <div className="flex flex-col gap-4">
      {state.error ? <Notice tone="bad">{copy[state.error]}</Notice> : null}
      <Input id="school-search" type="search" label={copy.search} placeholder={copy.searchHint} icon={Search01Icon} value={query} onChange={(event) => setQuery(event.target.value)} autoComplete="off" />
      {shown.length === 0 ? (
        <p className="m-0 text-sm text-muted">{copy.noMatch}</p>
      ) : (
        <ul className="m-0 grid list-none gap-2 p-0" aria-label={copy.title}>
          {shown.map((school) => (
            <li key={school.id}>
              <button
                type="button"
                onClick={() => setChosen(school)}
                className="flex w-full cursor-pointer items-center gap-4 rounded-md border-0 bg-surface p-4 text-left font-sans text-fg shadow-soft transition-shadow duration-(--dur-fast) hover:shadow-float focus-visible:outline-3 focus-visible:outline-focus"
              >
                <span className="grid size-12 shrink-0 place-items-center overflow-hidden rounded-sm bg-white">
                  {school.logoUrl ? (
                    // A logo from the public bucket; plain <img> because its host is the Supabase project.
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={school.logoUrl} alt="" className="size-full object-contain" />
                  ) : (
                    <Icon icon={School01Icon} size={22} className="text-brand" />
                  )}
                </span>
                <span className="min-w-0">
                  <span className="block truncate font-bold">{school.name}</span>
                  {school.place ? <span className="block truncate text-sm text-muted">{school.place}</span> : null}
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
      <Modal
        open={chosen !== null}
        onClose={() => setChosen(null)}
        title={chosen ? format(copy.confirmTitle, { school: chosen.name }) : ""}
        description={chosen ? format(copy.confirmBody, { school: chosen.name }) : undefined}
        actions={
          <form action={action} className="flex flex-wrap justify-end gap-2">
            <input type="hidden" name="school" value={chosen?.id ?? ""} />
            <Button type="button" variant="ghost" onClick={() => setChosen(null)}>
              {copy.cancel}
            </Button>
            <Button type="submit" disabled={pending}>
              {copy.confirmAction}
            </Button>
          </form>
        }
      />
    </div>
  );
}
