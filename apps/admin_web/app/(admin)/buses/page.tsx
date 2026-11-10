import { busLabel } from "@/lib/buses";
import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { Add01Icon } from "@hugeicons/core-free-icons";

import { ButtonLink } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { ListSkeleton } from "@/components/ui/ListSkeleton";
import { Notice } from "@/components/ui/Notice";
import { PageHeader } from "@/components/ui/PageHeader";
import { DataTable, Head, TableCard, Td, Th, Tr } from "@/components/ui/Table";
import { requireAdmin } from "@/lib/auth";
import { loadBuses } from "@/lib/buses-data";
import { getMessages } from "@/lib/i18n/server";

export const metadata: Metadata = { title: "Buses" };

// Depends on who is signed in, so it cannot be an instant navigation.
export const instant = false;

export default function BusesPage() {
  return (
    <Suspense fallback={<ListSkeleton rows={4} />}>
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
      <PageHeader
        title={t.buses.title}
        subtitle={t.buses.subtitle}
        help={{
          label: t.help.open,
          title: t.buses.help.title,
          intro: t.buses.help.intro,
          scenarios: Object.values(t.buses.help.scenarios),
          scenariosLabel: t.help.scenarios,
          closeLabel: t.help.close,
        }}
        action={
          <ButtonLink href="/buses/new" icon={Add01Icon}>
            {t.buses.add}
          </ButtonLink>
        }
      />

      {failed ? (
        <Notice tone="bad">{t.buses.loadError}</Notice>
      ) : buses.length === 0 ? (
        <EmptyState illustration="/illustrations/bus.webp" title={t.buses.empty} />
      ) : (
        <TableCard>
          <DataTable minWidth="28rem">
            <Head>
              <Th>{t.buses.columns.name}</Th>
              <Th>{t.buses.columns.plate}</Th>
              <Th>{t.buses.columns.capacity}</Th>
              <Th>{t.buses.columns.status}</Th>
            </Head>
            <tbody>
              {buses.map((bus) => (
                <Tr key={bus.id}>
                  <Td>
                    <Link href={`/buses/${bus.id}`} className="font-semibold text-fg no-underline hover:text-link">
                      {busLabel(bus)}
                    </Link>
                  </Td>
                  <Td className="tabular-nums text-muted">{bus.plate}</Td>
                  <Td>{bus.capacity}</Td>
                  <Td>
                    <Chip tone={bus.inService ? "ok" : "neutral"}>{bus.inService ? t.buses.status.inService : t.buses.status.outOfService}</Chip>
                  </Td>
                </Tr>
              ))}
            </tbody>
          </DataTable>
        </TableCard>
      )}
    </>
  );
}
