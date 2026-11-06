import { Delete02Icon, Tick02Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";

type Props = {
  /** Existing row: saved and removed. Leave out to add a new one. */
  id?: string;
  /** Extra values the action needs (the faculty a new department belongs to). */
  hidden?: Record<string, string>;
  name?: string;
  code?: string | null;
  /** Programs have no code. */
  withCode?: boolean;
  nameLabel: string;
  codeLabel?: string;
  codeHint?: string;
  save: (formData: FormData) => Promise<void>;
  remove?: (formData: FormData) => Promise<void>;
  saveLabel: string;
  removeLabel?: string;
};

const FIELD =
  "h-11 rounded-sm border border-line bg-surface px-3.5 font-sans text-sm text-fg placeholder:text-muted " +
  "transition-[border-color,box-shadow] duration-(--dur-fast) focus:border-focus focus:ring-3 focus:ring-focus/30 focus:outline-none";

/** One line of the academics page: a name, an optional code, and Save (and Remove for a row that exists). */
export function UnitRow({ id, hidden, name = "", code, withCode = true, nameLabel, codeLabel, codeHint, save, remove, saveLabel, removeLabel }: Props) {
  return (
    <form action={save} className="flex flex-wrap items-center gap-2">
      {id ? <input type="hidden" name="id" value={id} /> : null}
      {Object.entries(hidden ?? {}).map(([k, v]) => (
        <input key={k} type="hidden" name={k} value={v} />
      ))}
      <input name="name" defaultValue={name} required minLength={2} maxLength={120} aria-label={nameLabel} placeholder={nameLabel} className={`${FIELD} min-w-48 flex-1`} />
      {withCode ? (
        <input name="code" defaultValue={code ?? ""} maxLength={12} aria-label={codeLabel} placeholder={codeHint ?? codeLabel} className={`${FIELD} w-28`} />
      ) : null}
      <Button type="submit" variant="secondary" icon={Tick02Icon}>
        {saveLabel}
      </Button>
      {id && remove ? (
        <Button type="submit" variant="danger" icon={Delete02Icon} formAction={remove} formNoValidate>
          {removeLabel}
        </Button>
      ) : null}
    </form>
  );
}
