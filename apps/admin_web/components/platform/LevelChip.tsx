import { Alert02Icon, CheckmarkCircle02Icon, InformationCircleIcon, CancelCircleIcon, PowerSocket01Icon } from "@hugeicons/core-free-icons";

import { Chip } from "@/components/ui/Chip";
import { LEVEL_KEYS, LEVEL_TONES, type Level } from "@/lib/platform-health";

const ICONS = [CheckmarkCircle02Icon, InformationCircleIcon, Alert02Icon, CancelCircleIcon] as const;

type Labels = { ok: string; watch: string; needsHelp: string; critical: string; off: string };

/** A school's or a signal's level: a tone, an icon and its label, so the meaning never rests on colour alone. */
export function LevelChip({ level, labels }: { level: Level | null; labels: Labels }) {
  if (level === null) return <Chip icon={PowerSocket01Icon}>{labels.off}</Chip>;
  return (
    <Chip tone={LEVEL_TONES[level]} icon={ICONS[level]}>
      {labels[LEVEL_KEYS[level]]}
    </Chip>
  );
}
