-- Verify pembayaran:auth/init on pg

BEGIN;

select from auth.users;

ROLLBACK;
