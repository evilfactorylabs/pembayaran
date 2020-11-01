-- Verify pembayaran:app/init on pg

BEGIN;

-- check is pgcrypto loaded
select count(encode(digest('rahasia', 'sha1'), 'hex')) = 1;

-- check is uuid-ossp loaded
select count(uuid_generate_v4()) = 1;

ROLLBACK;
