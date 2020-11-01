-- Revert pembayaran:auth/endpoint from pg

BEGIN;

drop view api.users cascade;
drop view api.whoami cascade;

drop owned by special;
drop role special;

drop owned by customer;
drop role customer;

drop owned by member;
drop role member;

COMMIT;
