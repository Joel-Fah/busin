/**
 * Where the apps can be downloaded, from server settings read at request time. A store or file link appears only once
 * its setting is a valid https address; until then the page offers "Get notified" instead. None of these is a secret.
 *   LANDING_ANDROID_URL  a direct APK download
 *   LANDING_PLAY_URL     the Google Play listing
 *   LANDING_IOS_URL      the App Store listing
 */
export type Downloads = { apk: string | null; play: string | null; ios: string | null };

export function httpsUrl(value: string | undefined): string | null {
  const text = value?.trim();
  if (!text) return null;
  try {
    const url = new URL(text);
    return url.protocol === "https:" && url.hostname ? url.toString() : null;
  } catch {
    return null;
  }
}

export function downloads(env: Record<string, string | undefined> = process.env): Downloads {
  return { apk: httpsUrl(env.LANDING_ANDROID_URL), play: httpsUrl(env.LANDING_PLAY_URL), ios: httpsUrl(env.LANDING_IOS_URL) };
}
