import { Logout01Icon } from "@hugeicons/core-free-icons";

import { Button } from "@/components/ui/Button";
import { signOut } from "@/lib/auth-actions";

export function SignOutButton({ label }: { label: string }) {
  return (
    <form action={signOut}>
      <Button type="submit" variant="danger" icon={Logout01Icon}>
        {label}
      </Button>
    </form>
  );
}
