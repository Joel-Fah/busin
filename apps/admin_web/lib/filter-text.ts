import type { Messages } from "./i18n/messages";

/** The words every column filter needs besides its own column name. */
export function filterText(t: Messages) {
  return { searchLabel: t.columnFilter.search, noMatchLabel: t.columnFilter.noMatch, activeLabel: t.columnFilter.active };
}

/** The words the chips above a filtered list need. */
export function chipText(t: Messages) {
  return { clearAllLabel: t.columnFilter.clearAll, groupLabel: t.columnFilter.chipsLabel, removeLabel: t.columnFilter.remove };
}
