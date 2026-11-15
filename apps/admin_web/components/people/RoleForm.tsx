"use client";

import { UserMultiple02Icon } from "@hugeicons/core-free-icons";
import { useState } from "react";

import { Button } from "@/components/ui/Button";
import { Modal } from "@/components/ui/Modal";
import { Select } from "@/components/ui/Select";

type Role = "student" | "staff" | "admin";

type Copy = {
  label: string;
  hint: string;
  button: string;
  confirmTitle: string;
  toStaff: string;
  toStudent: string;
  other: string;
  cancel: string;
};

/**
 * The role of a verified member (ADR 0026). The roles offered follow the current one: a student can become staff, staff
 * a student or an administrator, an administrator staff. Changing asks first, saying what the change means and what
 * stops it (the database checks the same and explains a refusal).
 */
export function RoleForm({ id, current, labels, copy, action }: { id: string; current: Role; labels: Record<Role, string>; copy: Copy; action: (form: FormData) => Promise<void> }) {
  const options: Role[] = current === "student" ? ["student", "staff"] : current === "staff" ? ["student", "staff", "admin"] : ["staff", "admin"];
  const [role, setRole] = useState<Role>(current);
  const [asking, setAsking] = useState(false);
  const formId = `role-${id}`;
  const body = current === "student" && role === "staff" ? copy.toStaff : role === "student" ? copy.toStudent : copy.other;
  return (
    <form id={formId} action={action} className="flex flex-col gap-5">
      <input type="hidden" name="id" value={id} />
      <Select
        id="role"
        name="role"
        label={copy.label}
        icon={UserMultiple02Icon}
        hint={copy.hint}
        value={role}
        onChange={(value) => setRole(value as Role)}
        options={options.map((r) => ({ value: r, label: labels[r] }))}
      />
      <div>
        <Button type="button" disabled={role === current} onClick={() => setAsking(true)}>
          {copy.button}
        </Button>
      </div>
      <Modal
        open={asking}
        onClose={() => setAsking(false)}
        title={copy.confirmTitle}
        description={`${labels[current]} -> ${labels[role]}. ${body}`}
        actions={
          <>
            <Button type="button" variant="secondary" onClick={() => setAsking(false)}>
              {copy.cancel}
            </Button>
            <Button type="submit" form={formId}>
              {copy.button}
            </Button>
          </>
        }
      />
    </form>
  );
}
