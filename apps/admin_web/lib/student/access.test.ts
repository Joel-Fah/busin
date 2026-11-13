import { describe, expect, it } from "vitest";

import { isSetupComplete, studentAccess, type StudentProfile } from "./access";

const student: StudentProfile = { role: "student", status: "verified", school_id: "s1", full_name: "Amara N.", matricule: "ICT20", phone: "+237600000000" };

describe("who may use the student web app", () => {
  it("lets a verified student with their details in", () => {
    expect(studentAccess(student)).toEqual({ kind: "allowed" });
  });

  it("treats a missing profile as signed out", () => {
    expect(studentAccess(null)).toEqual({ kind: "signedOut" });
  });

  it("turns staff and administrators away whatever their status", () => {
    for (const role of ["staff", "admin"]) {
      for (const status of ["verified", "pending", "suspended"]) {
        expect(studentAccess({ ...student, role, status })).toEqual({ kind: "blocked", reason: "notStudent" });
      }
    }
  });

  it("blocks a suspended student", () => {
    expect(studentAccess({ ...student, status: "suspended" })).toEqual({ kind: "blocked", reason: "suspended" });
  });

  it("sends a pending student without a school to choose one, and one with a school to wait", () => {
    expect(studentAccess({ ...student, status: "pending", school_id: null })).toEqual({ kind: "needsSchool" });
    expect(studentAccess({ ...student, status: "pending" })).toEqual({ kind: "awaitingSchool" });
  });

  it("asks a verified student for the details the school needs first", () => {
    expect(studentAccess({ ...student, matricule: "  " })).toEqual({ kind: "needsSetup" });
    expect(studentAccess({ ...student, phone: null })).toEqual({ kind: "needsSetup" });
    expect(studentAccess({ ...student, full_name: "" })).toEqual({ kind: "needsSetup" });
  });

  it("checks setup on name, student number and phone only", () => {
    expect(isSetupComplete({ full_name: " A ", matricule: "1", phone: "2" })).toBe(true);
    expect(isSetupComplete({ full_name: "A", matricule: null, phone: "2" })).toBe(false);
  });
});
