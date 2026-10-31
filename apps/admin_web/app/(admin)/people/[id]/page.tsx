import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Suspense } from "react";

import { requireAdmin } from "@/lib/auth";
import { getMessages } from "@/lib/i18n/server";
import { isUuid } from "@/lib/ids";
import { ROLES, accountPill, initials, isPeopleDone, isPeopleErrorKey, rolePill } from "@/lib/people";
import { createClient } from "@/lib/supabase/server";

import { changeRole, changeStatus } from "../actions";

export const metadata: Metadata = { title: "Person" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

type Params = Promise<{ id: string }>;
type SearchParams = Promise<{ done?: string | string[]; error?: string | string[] }>;

export default function PersonPage({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <PersonDetail params={params} searchParams={searchParams} />
    </Suspense>
  );
}

function single(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

async function PersonDetail({ params, searchParams }: { params: Params; searchParams: SearchParams }) {
  const admin = await requireAdmin();
  const { locale, t } = await getMessages();
  const { id } = await params;
  if (!isUuid(id)) notFound();

  const supabase = await createClient();
  const { data: person } = await supabase
    .from("profiles")
    .select("id, full_name, email, phone, role, status, matricule, department, program, created_at")
    .eq("id", id)
    .maybeSingle();
  if (!person) notFound();

  const query = await searchParams;
  const doneParam = single(query.done);
  const errorParam = single(query.error);
  const done = isPeopleDone(doneParam) ? doneParam : null;
  const errorKey = isPeopleErrorKey(errorParam) ? errorParam : null;

  const isSelf = person.id === admin.userId;
  const joined = new Intl.DateTimeFormat(locale, { dateStyle: "medium", timeZone: admin.schoolTimezone }).format(
    new Date(person.created_at),
  );
  const d = t.people.detail;

  return (
    <>
      <p>
        <Link href="/people">{d.back}</Link>
      </p>

      <header className="person-head">
        <span className="avatar avatar-lg" aria-hidden="true">
          {initials(person.full_name, person.email)}
        </span>
        <div className="page-head">
          <h1>{person.full_name || person.email}</h1>
          <p className="row">
            <span className={rolePill(person.role)}>{t.role[person.role]}</span>
            <span className={accountPill(person.status)}>{t.accountStatus[person.status]}</span>
          </p>
        </div>
      </header>

      {done ? (
        <p className="success" role="status">
          {t.people.done[done]}
        </p>
      ) : null}
      {errorKey ? (
        <p className="notice" role="alert">
          {t.people.errors[errorKey]}
        </p>
      ) : null}

      <section className="card">
        <dl className="detail-grid">
          <div>
            <dt>{d.email}</dt>
            <dd>{person.email}</dd>
          </div>
          <div>
            <dt>{d.phone}</dt>
            <dd>{person.phone || "-"}</dd>
          </div>
          <div>
            <dt>{d.matricule}</dt>
            <dd>{person.matricule || "-"}</dd>
          </div>
          <div>
            <dt>{d.department}</dt>
            <dd>{person.department || "-"}</dd>
          </div>
          <div>
            <dt>{d.program}</dt>
            <dd>{person.program || "-"}</dd>
          </div>
          <div>
            <dt>{d.joined}</dt>
            <dd>{joined}</dd>
          </div>
        </dl>
      </section>

      {isSelf ? (
        <p className="card" role="note">
          {d.own}
        </p>
      ) : (
        <>
          <section className="card stack">
            <h2>{d.roleHeading}</h2>
            <form action={changeRole} className="stack">
              <input type="hidden" name="id" value={person.id} />
              <div className="field">
                <label htmlFor="role">{d.roleLabel}</label>
                <select id="role" name="role" defaultValue={person.role}>
                  {ROLES.map((role) => (
                    <option key={role} value={role}>
                      {t.role[role]}
                    </option>
                  ))}
                </select>
                <span className="muted">{d.roleHint}</span>
              </div>
              <div className="row">
                <button type="submit" className="btn btn-primary">
                  {d.roleButton}
                </button>
              </div>
            </form>
          </section>

          <section className="card stack">
            <h2>{d.accountHeading}</h2>
            {person.status === "suspended" ? (
              <form action={changeStatus} className="stack">
                <input type="hidden" name="id" value={person.id} />
                <input type="hidden" name="status" value="verified" />
                <p>{d.restoreHint}</p>
                <div className="row">
                  <button type="submit" className="btn btn-primary">
                    {d.restore}
                  </button>
                </div>
              </form>
            ) : (
              <details className="reject">
                <summary>{d.suspendOpen}</summary>
                <form action={changeStatus} className="stack">
                  <input type="hidden" name="id" value={person.id} />
                  <input type="hidden" name="status" value="suspended" />
                  <p>{d.suspendHint}</p>
                  <div className="row">
                    <button type="submit" className="btn btn-secondary btn-danger">
                      {d.suspendConfirm}
                    </button>
                  </div>
                </form>
              </details>
            )}
          </section>
        </>
      )}
    </>
  );
}
