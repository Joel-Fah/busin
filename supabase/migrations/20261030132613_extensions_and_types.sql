-- Extensions, enum types and safe default privileges.

create extension if not exists postgis with schema extensions;
create extension if not exists pgcrypto with schema extensions;

create type public.user_role as enum ('student', 'staff', 'admin');
create type public.account_status as enum ('pending', 'verified', 'suspended');
create type public.subscription_status as enum ('pending', 'approved', 'rejected', 'expired');
create type public.semester_name as enum ('fall', 'spring', 'summer');
create type public.trip_direction as enum ('inbound', 'outbound');
create type public.trip_status as enum ('scheduled', 'active', 'completed', 'cancelled');

-- Closed by default: objects created later in public grant nothing to the API
-- roles until a migration grants it explicitly.
alter default privileges for role postgres in schema public
  revoke all on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke all on sequences from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;

-- Server-only schema for helpers; it is not exposed through the API.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, supabase_auth_admin;
