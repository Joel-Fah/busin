import { signOut } from "@/lib/auth-actions";

export function SignOutButton({ label }: { label: string }) {
  return (
    <form action={signOut}>
      <button type="submit" className="btn btn-secondary">
        {label}
      </button>
    </form>
  );
}
