-- Revert pembayaran:auth/init from pg

BEGIN;

drop table auth.users;
drop schema auth cascade;

COMMIT;
