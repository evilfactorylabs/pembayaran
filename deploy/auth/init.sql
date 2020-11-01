-- Deploy pembayaran:auth/init to pg
-- requires: app/init

BEGIN;

create schema auth;

create table auth.users (
  id          uuid        unique default uuid_generate_v4(),
  name        text        null check (length(name) < 512),
  email       text        primary key check (email ~* '^.+@.+\..+$'),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  password    text        not null check (length(password) < 512),
  role        name        check (length(role) < 512)
);

COMMIT;
