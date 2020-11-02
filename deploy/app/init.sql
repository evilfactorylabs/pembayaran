-- Deploy pembayaran:app/init to pg
begin;

create extension if not exists "pgcrypto";

create extension if not exists "uuid-ossp";

-- pgjwt extension, source: https://github.com/michelp/pgjwt
create or replace function url_encode (data bytea)
  returns text
  language sql
  as $$
  select
    translate(encode(data, 'base64'), E'+/=\n', '-_');

$$;

create or replace function url_decode (data text)
  returns bytea
  language sql
  as $$
  with t as (
    select
      translate(data, '-_', '+/') as trans
),
rem as (
  select
    length(t.trans) % 4 as remainder
  from
    t) -- compute padding size
  select
    decode(t.trans || case when rem.remainder > 0 then
        repeat('=', (4 - rem.remainder))
      else
        ''
      end, 'base64')
  from
    t,
    rem;

$$;

create or replace function algorithm_sign (signables text, secret text, algorithm text)
  returns text
  language sql
  as $$
  with alg as (
    select
      case when algorithm = 'HS256' then
        'sha256'
      when algorithm = 'HS384' then
        'sha384'
      when algorithm = 'HS512' then
        'sha512'
      else
        ''
      end as id) -- hmac throws error
    select
      url_encode (hmac(signables, secret, alg.id))
    from
      alg;

$$;

create or replace function sign (payload json, secret text, algorithm text default 'HS256')
  returns text
  language sql
  as $$
  with header as (
    select
      url_encode (convert_to('{"alg":"' || algorithm || '","typ":"JWT"}', 'utf8')) as data
),
payload as (
  select
    url_encode (convert_to(payload::text, 'utf8')) as data
),
signables as (
  select
    header.data || '.' || payload.data as data
  from
    header,
    payload
)
select
  signables.data || '.' || algorithm_sign (signables.data, secret, algorithm)
from
  signables;

$$;

create or replace function verify (token text, secret text, algorithm text default 'HS256')
  returns table (
    header json,
    payload json,
    valid boolean)
  language sql
  as $$
  select
    convert_from(url_decode (r[1]), 'utf8')::json as header,
    convert_from(url_decode (r[2]), 'utf8')::json as payload,
    r[3] = algorithm_sign (r[1] || '.' || r[2], secret, algorithm) as valid
  from
    regexp_split_to_array(token, '\.') r;

$$;

-- end pgjwt extension
create schema api;

create role anon nologin;

grant usage on schema api to anon;

create role authenticator noinherit nologin;

grant anon to authenticator;

commit;
