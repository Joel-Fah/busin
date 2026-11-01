import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { requireAdmin } from "@/lib/auth";
import { loadBuses } from "@/lib/buses-data";
import { getMessages } from "@/lib/i18n/server";

export const metadata: Metadata = { title: "Buses" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function BusesPage() {
  return (
    <Suspense fallback={<section aria-busy="true" />}>
      <BusesList />
    </Suspense>
  );
}

async function BusesList() {
  await requireAdmin();
  const { t } = await getMessages();
  const { buses, failed } = await loadBuses();

  return (
    <>
      <header className="page-head">
        <h1>{t.buses.title}</h1>
        <p>{t.buses.subtitle}</p>
      </header>

      <div className="row">
        <Link className="btn btn-primary" href="/buses/new">
          {t.buses.add}
        </Link>
      </div>

      {failed ? (
        <p className="notice" role="alert">
          {t.buses.loadError}
        </p>
      ) : buses.length === 0 ? (
        <p className="card">{t.buses.empty}</p>
      ) : (
        <div className="table-wrap card">
          <table>
            <thead>
              <tr>
                <th scope="col">{t.buses.columns.plate}</th>
                <th scope="col">{t.buses.columns.capacity}</th>
                <th scope="col">{t.buses.columns.status}</th>
              </tr>
            </thead>
            <tbody>
              {buses.map((bus) => (
                <tr key={bus.id}>
                  <td>
                    <Link href={`/buses/${bus.id}`}>{bus.plate}</Link>
                  </td>
                  <td>{bus.capacity}</td>
                  <td>
                    <span className={bus.inService ? "pill pill-ok" : "pill"}>
                      {bus.inService ? t.buses.status.inService : t.buses.status.outOfService}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
