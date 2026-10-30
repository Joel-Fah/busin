# 0004: Account ownership

Status: accepted, 2026-10-30.

## Decision
New cloud resources (Supabase, Google Cloud OAuth clients, the FCM Firebase project, hosting) are created under the owner's personal Google account, not the ICT University organization account. A second owner is added to each as a backup. The existing ICTU Firebase project is left untouched.

## Consequences
Google sign-in uses an External consent screen so users from any school can sign in; access is limited by the database allow-list, not by Google. Resources can later be moved under a company organization if one is created.
