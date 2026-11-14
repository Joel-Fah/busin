"use client";

import { BookOpen01Icon, Building03Icon, Call02Icon, IdIcon, Mortarboard01Icon, UserIcon } from "@hugeicons/core-free-icons";
import { useActionState, useState } from "react";

import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Notice } from "@/components/ui/Notice";
import { Select } from "@/components/ui/Select";
import type { StudentCopy } from "@/lib/i18n/student";
import { saveSetup, type SetupState } from "@/lib/student/onboarding";
import Link from "next/link";

export type Academics = {
  faculties: { id: string; name: string }[];
  departments: { id: string; facultyId: string; name: string }[];
  programs: { id: string; name: string }[];
};

/**
 * Name, student number and phone (required), then program, faculty and department (optional), as the app's setup screen.
 * The faculty only narrows the department list; it is not stored.
 */
export function SetupForm({
  copy,
  fields,
  academics,
  initial,
  save = saveSetup,
  submitLabel,
  cancel,
}: {
  copy: StudentCopy["setup"];
  fields: StudentCopy["fields"];
  academics: Academics;
  initial: SetupState["values"];
  /** The setup gate by default; the profile passes its own action. */
  save?: (previous: SetupState, formData: FormData) => Promise<SetupState>;
  submitLabel?: string;
  cancel?: { href: string; label: string };
}) {
  const [state, action, pending] = useActionState<SetupState, FormData>(save, { problems: {}, error: null, values: initial });
  const [faculty, setFaculty] = useState(state.values.faculty);
  const [department, setDepartment] = useState(state.values.department);
  const departments = academics.departments.filter((d) => d.facultyId === faculty);
  const problem = (key: keyof SetupState["problems"]) => (state.problems[key] ? fields.problems[state.problems[key]!] : undefined);
  const none = { value: "", label: fields.none };

  return (
    <form action={action} className="flex flex-col gap-4" noValidate>
      {state.error ? <Notice tone="bad">{copy.failed}</Notice> : null}
      <Input id="fullName" name="fullName" label={fields.fullName} hint={fields.fullNameHint} icon={UserIcon} defaultValue={state.values.fullName} error={problem("fullName")} autoComplete="name" required maxLength={80} />
      <Input id="matricule" name="matricule" label={fields.matricule} hint={fields.matriculeHint} icon={IdIcon} defaultValue={state.values.matricule} error={problem("matricule")} autoComplete="off" autoCapitalize="characters" required maxLength={32} />
      <Input id="phone" name="phone" type="tel" label={fields.phone} hint={fields.phoneHint} icon={Call02Icon} defaultValue={state.values.phone} error={problem("phone")} autoComplete="tel" inputMode="tel" required />
      {/* Program first, then faculty and its department (the owner's order for setup). */}
      {academics.programs.length > 0 ? (
        <Select
          id="program"
          name="program"
          label={fields.program}
          icon={Mortarboard01Icon}
          placeholder={fields.programHint}
          options={[none, ...academics.programs.map((p) => ({ value: p.id, label: p.name }))]}
          defaultValue={state.values.program}
        />
      ) : null}
      {academics.faculties.length > 0 ? (
        <>
          <Select
            id="faculty"
            name="faculty"
            label={fields.faculty}
            icon={Building03Icon}
            placeholder={fields.facultyHint}
            options={[none, ...academics.faculties.map((f) => ({ value: f.id, label: f.name }))]}
            value={faculty}
            onChange={(value) => {
              setFaculty(value);
              setDepartment("");
            }}
          />
          <Select
            id="department"
            name="department"
            label={fields.department}
            icon={BookOpen01Icon}
            placeholder={faculty ? fields.departmentHint : fields.departmentFirst}
            options={[none, ...departments.map((d) => ({ value: d.id, label: d.name }))]}
            value={department}
            onChange={setDepartment}
            disabled={!faculty}
          />
        </>
      ) : null}
      <Button type="submit" className="mt-2 h-14 w-full text-base" disabled={pending}>
        {submitLabel ?? copy.save}
      </Button>
      {cancel ? (
        <Link href={cancel.href} className="inline-flex h-12 items-center justify-center rounded-sm font-semibold text-fg no-underline hover:bg-surface-2">
          {cancel.label}
        </Link>
      ) : null}
    </form>
  );
}
