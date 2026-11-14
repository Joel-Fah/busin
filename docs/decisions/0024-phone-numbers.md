# 0024: Phone numbers

Status: accepted, 2026-11-14 (the owner asked for one consistent format, and a country and phone field in every app).

## Context
Phone numbers were saved as typed: local (`677123456`), with a trunk 0, with or without `+237`, and for schools with
spaces. The student column had no rule at all. Schools have students and staff of many nationalities.

## Decision
1. **Stored as E.164.** A `+`, the country code and the number, digits only: `+237677123456`. The database checks the
   shape on `profiles.phone` and `schools.phone` (`^\+[1-9][0-9]{6,14}$`).
2. **Typed for a country.** Every phone field has a country next to it (a flag and a searchable list, on one row). The
   number is formatted as it is typed in that country's way, and a number pasted with `+` switches the country. People
   rarely type the code; they do not have to.
3. **Real numbers only, checked on the device.** The apps check the number exists for its country with the
   libphonenumber metadata (`libphonenumber-js` on the web, `phone_numbers_parser` in Dart) and say why when it does
   not. A leading 0 where the country has none (Cameroon) is dropped, and a number valid in a country that shares the
   code (+44: the UK, Guernsey, Jersey) is kept.
4. **The starting country is never fixed in the code:** the saved number's, else the school's own number's, else the
   device's or browser's region, else Cameroon as the last fallback.
5. **Shown in international form with spaces** (`+237 6 77 12 34 56`), through one helper on each side.
6. **Older numbers tidied once** by the migration: international ones kept, bare Cameroonian ones given `+237`, the
   rest cleared (a student is then asked again by the setup gate; a school shows no phone until set).

## Consequences
- New dependencies: `libphonenumber-js` (MIT) and `country-flag-icons` (MIT, flag SVGs: emoji flags are not allowed
  here) on the web; `phone_numbers_parser` (MIT) and `country_flags` (MIT) in Dart.
- Push, SMS or calling services later can use the stored numbers as they are.
