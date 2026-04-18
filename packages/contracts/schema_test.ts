import { assertEquals, assertThrows } from "std/assert";
import { ddmmyyyyToIso, isoToDdmmyyyy } from "./schema.ts";

Deno.test("ddmmyyyyToIso converts UI date", () => {
  assertEquals(ddmmyyyyToIso("17.04.2026"), "2026-04-17");
});

Deno.test("isoToDdmmyyyy converts storage date", () => {
  assertEquals(isoToDdmmyyyy("2026-04-17"), "17.04.2026");
});

Deno.test("ddmmyyyyToIso rejects bad input", () => {
  assertThrows(() => ddmmyyyyToIso("2026/04/17"));
});
