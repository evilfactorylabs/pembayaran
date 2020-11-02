-- Revert pembayaran:auth/init from pg
begin;

drop table auth.users;

drop schema auth cascade;

commit;
