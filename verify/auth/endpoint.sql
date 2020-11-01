-- Verify pembayaran:auth/endpoint on pg

BEGIN;

-- can register
select api.signup('fariz@evilfactory.id', 'rahasia');

-- can login
select api.login('fariz@evilfactory.id', 'rahasia');

-- can't register with same email address (duplicate)
select api.signup('fariz@evilfactory.id', 'rahasia') where false;

ROLLBACK;
