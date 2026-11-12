/** Pure helpers for filters that live in a list's address. Kept separate so they are unit tested. */

import { isUuid } from "./ids";
import { first } from "./pagination";

type Value = string | number | null | undefined;

/** A list address from its parameters. Empty and null ones are left out, so the plain list has a plain address. */
export function listHref(path: string, params: Record<string, Value>): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === null || value === undefined || value === "") continue;
    query.set(key, String(value));
  }
  const text = query.toString();
  return text ? `${path}?${text}` : path;
}

/** A query value that must be an id, or null. Anything else means "no filter". */
export function uuidParam(value: string | string[] | undefined): string | null {
  const candidate = first(value);
  return isUuid(candidate) ? candidate : null;
}

/** A query value that must be one of `allowed`, or null. */
export function choiceParam<T extends string>(value: string | string[] | undefined, allowed: readonly T[]): T | null {
  const candidate = first(value);
  return allowed.find((item) => item === candidate) ?? null;
}

/** The placeholder a server page puts in an address, for the client to swap for the value a person picks. */
export const VALUE_TOKEN = "__VALUE__";

/** Swaps the placeholder for the picked value. */
export function fillHref(template: string, value: string): string {
  return template.replace(VALUE_TOKEN, encodeURIComponent(value));
}
