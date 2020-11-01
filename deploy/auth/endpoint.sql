-- Deploy pembayaran:auth/endpoint to pg

BEGIN;

--- role things
-- ada 3 jenis peranan untuk saat ini untuk hal-hal terkait pengguna
--
-- 1. admin (special), dapat mengakses *seluruh* data
-- 2. pelanggan (customer), dapat mengakses *hanya* data yang dimiliki oleh si pengguna
-- 3. anggota (member), dapat mengakses *hanya* data terkait transaksi yang ditunjukkan kepada pengguna
create role special nologin;
create role customer nologin;
create role member nologin;

-- alias
create type auth.signup_success as (message text);
create type auth.jwt_token as (token text);
create type auth.jwt_pre_claims as (_role name, _id uuid);
create type auth.jwt_claims as (id text, role text, email text);

-- buat tabel virtual untuk menampilkan semua data pengguna yang sekiranya penting saja
create view api.users as
	select id, name, email, created_at, updated_at, role from auth.users;

-- buat tabel virtual yang merepresentasikan siapa pengguna sekarang berdasarkan jwt token yang diberikan
create view api.whoami as
	select id, email, role from auth.users
    where id = current_setting('request.jwt.claim.user_id', true)::uuid;

-- hash password, dan buat salt menggunakan algoritma blowfish
-- harusnya dijalankan setiap ada operasi insert/update di auth.users
create or replace function auth.hash_pass()
  returns trigger
  language plpgsql
  as $$
begin
  if tg_op = 'INSERT' or new.password <> old.password then
    new.password = crypt(new.password, gen_salt('bf'));
  end if;
  return new;
end
$$;

-- cek apakah email tersebut sudah ada
-- dijalankan setiap ada operasi insert/update di auth.users
create or replace function auth.check_existing_email()
  returns trigger
  language plpgsql
  as $$
begin
  if exists (select 1 from auth.users as r where r.email = new.email) then
    raise foreign_key_violation using message =
      'email is already registered: ' || new.email;
    return null;
  end if;
  return new;
end
$$;

-- dapatkan user_role dan user_id berdasarkan email & password
create or replace function auth.get_user_role_and_id(email text, password text)
 returns auth.jwt_pre_claims
 language plpgsql
  as $$
declare
  result auth.jwt_pre_claims;
begin
	select role, id from auth.users
    where users.email = get_user_role_and_id.email
      and users.password = crypt(get_user_role_and_id.password, users.password) into result;
  return result;
end;
$$;

-- fungsi login
-- TODO: create something to check non-exist email
create or replace function api.login(email text, password text)
  returns auth.jwt_token
  language plpgsql
  as $$
declare
  token auth.jwt_token;
  check_user auth.jwt_pre_claims;
  loggedin_user auth.jwt_claims;
begin
  select _role, _id from auth.get_user_role_and_id(email, password) into check_user;
  if check_user._id is null then
    raise invalid_password using message = 'invalid email or password';
  end if;
  select check_user._id as id, check_user._role as role, login.email as email into loggedin_user;
  select public.sign(row_to_json(r), current_setting('app.jwt_secret')) as token
    from (
      select
        loggedin_user.role as role,
        loggedin_user.id as user_id,
        loggedin_user.email as email,
        extract(epoch from now())::integer + 2592000 as exp -- expire = 1 bulan, todo: buat refresh token
    ) r into token;
  return token;
end;
$$;

-- fungsi signup
create or replace function api.signup(email text, password text)
  returns auth.signup_success
  language plpgsql
  as $$
declare
  response auth.signup_success;
begin
  insert into auth.users ("email", "password", "role") values (email, password, 'customer');
  select('success') into response;
  return response;
end;
$$;

--- trigger things

-- panggil hash password (diatas) setiap kali data 'password' berubah
-- dijalankan setiap ada operasi insert/update di auth.users
create trigger hash_pass
  before insert or update on auth.users
	for each row
	execute procedure auth.hash_pass();

-- cek apakah email tersebut sudah terdaftar atau belum?
-- dijalankan setiap ada operasi insert/update di auth.users
create trigger ensure_email_is_not_exist
  before insert or update on auth.users
  for each row
  execute procedure auth.check_existing_email();

-- berikan role2 ini ke authenticator
grant special to authenticator;
grant customer to authenticator;
grant member to authenticator;

-- beri akses skema api dan auth
grant usage on schema api,auth to special, customer, anon;

-- beri akses select dan insert ke anon
grant select, insert on table auth.users to anon;

-- beri akses select kesini cuma buat customer
-- fixme: sepertinya ini perlu dipikirkan ulang
grant select on api.whoami to customer;

-- beri akses menjalankan fungsi ini ke anon
grant execute on function api.login(text, text) to anon;
grant execute on function api.signup(text, text) TO anon;

-- yes
grant all on api.users to special;

COMMIT;
