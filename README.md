# pembayaran

TBD

## Struktur Direktori

Project ini ditenagai oleh [sqitch](https://sqitch.org/) untuk mengatur migrasi dan
[Postgrest](https://postgrest.org/en/v7.0.0/) sebagai "backend" nya.

Ada 3 direktori inti yang berguna untuk berinteraksi dengan basis data (Postgres), antara lain:

- `deploy`: Tempat dimana kita melakukan proses migrasi
- `revert`: Tempat dimana kita melakukan proses *rollback*
- `verify`: Tempat dimana kita melakukan proses verifikasi setelah melakukan migrasi

Yang mana di setiap 3 direktori diatas, terdapat direktori lagi yang merepresentasikan *domain*.

## Memulai

Agar lebih yoi, silahkan siapkan Docker untuk menjalankan basis data Postgres sebagai *container* yang berjalan
diatas Docker, bukan diatas sistem operasi **langsung** agar lebih mudah diatur.

### Menjalankan Postgres

Jika sudah, silahkan unduh *image* dengan nama `postgres` dengan perintah berikut:

```bash
docker pull postgres
```

Lalu jalankan dengan nama `postgres` biar lebih gampang:

```bash
docker run --name postgres \
  -p 5433:5432 \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -d postgres
```

Setelah itu buat basis data dengan nama `pembayaran` di *container* tersebut:

```bash
docker exec -ti postgres createdb pembayaran -U postgres
```

Maka Postgres kita sudah siap digunakan!

### Menjalankan Sqitch

Disini kita akan menggunakan Sqitch [versi Docker](https://sqitch.org/download/docker/) agar lebih fleksibel. Silahkan
lakukan perintah yang sudah diinstruksikan di halaman tersebut, lalu verifikasi proses instalasi dengan menjalankan `sqitch --version`.

Untuk memverifikasi apakah `sqitch` sudah dapat berkomunikasi dengan postgres kita, silahkan lakukan migrasi dengan melakukan perintah berikut:

```bash
sqitch deploy
```

Jika berhasil, berarti berhasil.

### Mengatur aplikasi

Pertama, kita harus mengatur nilai `app.jwt_secret` terlebih dahulu, karena kita melakukan pembuatan (jwt) token di lapisan postgres,
jadi silahkan jalankan perintah berikut untuk mengaturnya:

```bash
docker exec -ti postgres \
  psql -U postgres -d pembayaran \
    -c "alter database pembayaran set "app.jwt_secret" TO '<jwt_secret_disini>'"
```

Tentu saja si `<jwt_secret_disini>` harus diubah, bisa dengan menjalankan perintah berikut untuk membuat kata *random*:

```bash
env LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c32; echo
```

Lalu salin kata yang muncul untuk mengubah nilai `<jwt_secret_disini>` diatas, contoh:

```bash
docker exec -ti postgres \
  psql -U postgres -d pembayaran \
    -c "alter database pembayaran set "app.jwt_secret" TO 'TniTYq4ugMHhSLewTk17GdoUIVeY9UKd'"
```

Silahkan verifikasi dengan menjalankan perintah berikut:

```bash
docker exec -ti postgres \
  psql -U postgres -d pembayaran \
    -c "select current_setting('app.jwt_secret')"
```

Jika sesuai harapan, berarti ~~sesuai harapan~~ berhasil.

Oh iya, jangan lupa untuk men-set `jwt_secret` **yang sama** juga di `pembayaran.conf`

### Mengatur postgrest

Sejauh ini kita menggunakan [Postgrest](https://postgrest.org) dalam menjalankan aplikasi ini, selain kamu harus mempelajari
terlebih dahulu tentang Postgrest, pastinya kamu harus memiliki postgrest nya juga di mesin kamu.

Silahkan pasang terlebih dahulu si `postgrest` [disini](https://postgrest.org/en/v7.0.0/install.html), lalu jalankan perintah berikut
untuk memastikan si `postgrest` sudah terpasang:

```bash
postgrest -h
```

Jika ~~exit code nya 0~~ muncul keluaran yang intinya bukan galat, berarti sudah berhasil terpasang!

### Menjalankan aplikasi

Oke banyak banget ya upacaranya, mau buat berkas bootstrap.sh tapi masih males hehe anywayyy.

Pertama, kita harus membuat berkas bernama `pembayaran.conf` yang sumbernya bisa diambil dari `pembayaran.conf.example`
yang isinya bisa disesuaikan sesuai instruksi. Salin berkas tersebut dengan perintah berikut:

```bash
cp pembayaran.conf.example pembayaran.conf
```

Jika isinya sudah disesuaikan, sekarang kita jalankan aplikasi kita dengan cara menjalankan perintah berikut:

```bash
postgrest pembayaran.conf
```

Jika berhasil, maka kita sudah bisa mengakses *instance* postgrest kita di localhost:3000, dan bisa kita lihat dengan melakukan perintah berikut:

```bash
curl -s localhost:3000
```

Silahkan pakai `jq(1)` untuk mempercantik keluarannya. Atau bisa menggunakan [insomnia.rest](https://insomnia.rest), [httpie](https://httpie.org),
[Hoppscotch](https://hoppscotch.io/) bila kurang terbiasa dengan `curl(1)`.

Jika ada kendala dalam menjalankan aplikasi ini, mohon untuk membuat *issue* [disini](https://github.com/evilfactorylabs/pembayaran/issues/new?title=Kagak+bisa+jalan+nih+browww).

## Berkontribusi

TBD.

## Pemelihara

- Fariz (@evilfactorylabs)

## API

### Auth

Untuk ber-interaksi dengan hal-hal terkait autentikasi dan otorisasi di aplikasi

#### Signup

Untuk melakukan pendaftaran.

```
POST /rpc/signup

Content-Type: application/json

{
  "email": "string",
  "password": "string"
}
```

Contoh:

```bash
curl -X POST http://localhost:3000/rpc/signup \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "fariz@gmail.com",
    "password": "Rahasia"
  }'
```

#### Login

Untuk melakukan autentikasi.

```
POST /rpc/login

Content-Type: application/json

{
  "email": "string",
  "password": "string"
}
```

Contoh:

```bash
curl -X POST http://localhost:3000/rpc/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "fariz@evilfactory.id",
    "password": "Rahasia"
  }'
```

#### Whoami

Untuk mengetahui *siapa saya?* berdasarkan token yang dibawa.

```
GET /whoami

Content-Type: application/json
Authorization: Bearer <jwt_token>
```

Contoh:

```bash
curl http://localhost:3000/whoami \
  -H 'Authorization: Bearer <jwt_token_disini>' \
  -H 'Content-Type: application/json'
```