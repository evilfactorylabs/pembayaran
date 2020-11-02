-- Verify pembayaran:auth/init on pg
begin;

select
from
  auth.users;

rollback;
