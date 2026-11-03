import { notFound, redirect } from "next/navigation";

import { isUuid } from "@/lib/ids";

// Editing a stop now happens in a sheet on the Stops page. This keeps old links working.
export const instant = false;

export default async function StopPage({ params }: { params: Promise<{ id: string }> }): Promise<never> {
  const { id } = await params;
  if (!isUuid(id)) notFound();
  redirect(`/stops?edit=${id}`);
}
