import { describe, expect, it } from "vitest";

import { MAP_BUDGET_KEY, MAP_LOAD_LIMIT, MAP_LOAD_WINDOW_MS, canLoadMap, mapBudgetAvailable, parseHistory, recent, takeMapLoad, withLoad } from "./budget";

const NOW = 1_800_000_000_000;

function memory(initial?: string) {
  const store = new Map<string, string>(initial ? [[MAP_BUDGET_KEY, initial]] : []);
  return {
    getItem: (key: string) => store.get(key) ?? null,
    setItem: (key: string, value: string) => void store.set(key, value),
    raw: () => store.get(MAP_BUDGET_KEY),
  };
}

describe("parseHistory", () => {
  it("reads a list of times and ignores anything damaged", () => {
    expect(parseHistory("[1,2,3]")).toEqual([1, 2, 3]);
    expect(parseHistory('[1,"x",null,2]')).toEqual([1, 2]);
    expect(parseHistory("not json")).toEqual([]);
    expect(parseHistory('{"a":1}')).toEqual([]);
    expect(parseHistory(null)).toEqual([]);
  });
});

describe("the rolling window", () => {
  it("counts only loads inside it", () => {
    const history = [NOW - MAP_LOAD_WINDOW_MS - 1, NOW - MAP_LOAD_WINDOW_MS + 1000, NOW - 5];
    expect(recent(history, NOW)).toHaveLength(2);
  });

  it("allows loads up to the limit and no more", () => {
    const some = Array.from({ length: MAP_LOAD_LIMIT - 1 }, (_, i) => NOW - i);
    expect(canLoadMap(some, NOW)).toBe(true);
    expect(canLoadMap(withLoad(some, NOW), NOW)).toBe(false);
  });

  it("frees the budget again as old loads age out", () => {
    const full = Array.from({ length: MAP_LOAD_LIMIT }, () => NOW);
    expect(canLoadMap(full, NOW)).toBe(false);
    expect(canLoadMap(full, NOW + MAP_LOAD_WINDOW_MS + 1)).toBe(true);
  });

  it("ignores times in the future, so a wrong clock cannot lock the map for good", () => {
    expect(recent([NOW + 10_000_000], NOW)).toEqual([]);
  });
});

describe("takeMapLoad", () => {
  it("records each load and refuses once the budget is spent", () => {
    const storage = memory();
    for (let i = 0; i < MAP_LOAD_LIMIT; i++) expect(takeMapLoad(storage, NOW + i)).toBe(true);
    expect(takeMapLoad(storage, NOW + MAP_LOAD_LIMIT)).toBe(false);
    expect(parseHistory(storage.raw() ?? null)).toHaveLength(MAP_LOAD_LIMIT);
  });

  it("does not record a refused load", () => {
    const storage = memory(JSON.stringify(Array.from({ length: MAP_LOAD_LIMIT }, () => NOW)));
    expect(takeMapLoad(storage, NOW)).toBe(false);
    expect(parseHistory(storage.raw() ?? null)).toHaveLength(MAP_LOAD_LIMIT);
  });

  it("allows the load when storage is missing or throws", () => {
    expect(takeMapLoad(null, NOW)).toBe(true);
    const broken = {
      getItem: () => {
        throw new Error("blocked");
      },
      setItem: () => {
        throw new Error("blocked");
      },
    };
    expect(takeMapLoad(broken, NOW)).toBe(true);
  });
});

describe("mapBudgetAvailable", () => {
  it("reports the state without recording anything", () => {
    const storage = memory();
    expect(mapBudgetAvailable(storage, NOW)).toBe(true);
    expect(storage.raw()).toBeUndefined();
    const spent = memory(JSON.stringify(Array.from({ length: MAP_LOAD_LIMIT }, () => NOW)));
    expect(mapBudgetAvailable(spent, NOW)).toBe(false);
    expect(mapBudgetAvailable(null, NOW)).toBe(true);
  });
});
