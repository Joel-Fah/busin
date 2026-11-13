/**
 * Where the browser keeps the boarding-code key between visits (ADR 0021): IndexedDB, which can hold a CryptoKey object
 * as it is, so the non-extractable key is stored without its bytes ever being readable. One record per student, with the
 * last day it may be used (the end of the semester it was given for). Everything here fails quietly: a browser that
 * refuses storage (private mode) simply needs the internet each time.
 */
const DB = "busin";
const STORE = "boarding-keys";

export type StoredKey = { userId: string; key: CryptoKey; validUntil: string };

function open(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB, 1);
    request.onupgradeneeded = () => {
      if (!request.result.objectStoreNames.contains(STORE)) request.result.createObjectStore(STORE, { keyPath: "userId" });
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function run<T>(mode: IDBTransactionMode, act: (store: IDBObjectStore) => IDBRequest<T>): Promise<T | null> {
  try {
    const db = await open();
    return await new Promise<T>((resolve, reject) => {
      const request = act(db.transaction(STORE, mode).objectStore(STORE));
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    }).finally(() => db.close());
  } catch {
    return null;
  }
}

export async function saveKey(record: StoredKey): Promise<void> {
  await run("readwrite", (store) => store.put(record));
}

/** The student's key while it is still valid on the school's `today`; an expired one is deleted. */
export async function loadKey(userId: string, today: string): Promise<CryptoKey | null> {
  const record = (await run<StoredKey | undefined>("readonly", (store) => store.get(userId))) ?? null;
  if (!record) return null;
  if (record.validUntil < today) {
    await deleteKey(userId);
    return null;
  }
  return record.key;
}

export async function deleteKey(userId: string): Promise<void> {
  await run("readwrite", (store) => store.delete(userId));
}

/** Everything, for signing out: the keys of whoever used this browser. */
export async function clearKeys(): Promise<void> {
  await run("readwrite", (store) => store.clear());
}
