import { redirect } from "next/navigation";

// Adding a stop now happens in a sheet on the Stops page. This keeps old links working.
export const instant = false;

export default function NewStopPage(): never {
  redirect("/stops?add=1");
}
