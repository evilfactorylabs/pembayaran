-- Revert pembayaran:app/init from pg

BEGIN;

drop schema api cascade;

reassign owned by anon to postgres;
drop owned by anon;
drop role anon;

drop role authenticator;

COMMIT;
