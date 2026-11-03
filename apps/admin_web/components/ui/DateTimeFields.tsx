import type { InputHTMLAttributes } from "react";
import { Calendar02Icon, Clock01Icon } from "@hugeicons/core-free-icons";

import { Input } from "./Input";

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, "id" | "type"> & {
  id: string;
  label: string;
  hint?: string;
  error?: string;
};

/** A date field. The browser's date picker opens from it, so it is easy to use by touch and keyboard. */
export function DateField(props: Props) {
  return <Input {...props} type="date" icon={Calendar02Icon} />;
}

/** A time field. */
export function TimeField(props: Props) {
  return <Input {...props} type="time" icon={Clock01Icon} />;
}

/** A date and a time in one field, typed in the school's local time. */
export function DateTimeField(props: Props) {
  return <Input {...props} type="datetime-local" icon={Calendar02Icon} />;
}
