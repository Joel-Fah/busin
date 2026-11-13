/** Replaces `{name}` placeholders. Unknown placeholders are left as they are. Kept alone so any page can use it without a catalogue. */
export function format(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (match, key: string) => (key in values ? String(values[key]) : match));
}
