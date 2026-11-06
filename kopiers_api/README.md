# Kopiers API

Backend REST API Node.js/Express untuk aplikasi Flutter Admin dan Customer. Karena `db_crm_kopiers` sudah memiliki skema lama, proyek ini menyiapkan database terpisah `db_crm_kopiers_v2` dan tidak mengubah database lama. Flutter hanya berkomunikasi dengan API, bukan langsung ke MySQL.

## Menjalankan lokal

1. Jalankan MySQL dari XAMPP, lalu impor `database/schema.sql` melalui phpMyAdmin.
   Untuk database yang sudah berjalan, jalankan `database/migrations/002_reward_redemption_claims.sql`
   sebelum memperbarui API.
2. Salin `.env.example` menjadi `.env`, lalu isi konfigurasi MySQL dan `JWT_SECRET`. Gunakan secret acak minimal 32 karakter.
3. Dari folder `kopiers_api`, jalankan `npm install`.
4. Buat akun admin (password minimal 12 karakter):

   ```powershell
   npm run create-admin -- "Admin Kopiers" 08123456789 admin@kopiers.local "GantiPasswordYangKuat"
   ```

5. Jalankan API:

   ```powershell
   npm run dev
   ```

   Health check: `GET http://localhost:3000/api/health`.

## Endpoint yang tersedia

Semua endpoint selain health check dan auth register/login memerlukan `Authorization: Bearer <token>`. Endpoint admin memeriksa role di backend. Token logout dibatalkan dengan menaikkan `token_version`.

| Method | Endpoint | Akses |
|---|---|---|
| POST | `/api/auth/register`, `/api/auth/login` | Publik |
| GET | `/api/auth/me`, POST `/api/auth/logout` | Login |
| GET | `/api/dashboard` | Admin |
| GET | `/api/customers`, `/api/customers/:id` | Admin |
| POST | `/api/customers` | Admin |
| PATCH | `/api/customers/:id`, `/api/customers/:id/status` | Admin |
| GET/PATCH | `/api/customers/me` | Customer |
| GET | `/api/customers/me/transactions` atau `/api/transactions/me` | Customer |
| GET/POST/PATCH/DELETE | `/api/products` | Login / Admin untuk perubahan |
| GET/POST | `/api/transactions` | Admin |
| GET/POST/PATCH | `/api/complaints` | Customer/admin sesuai kepemilikan dan role; admin dapat filter `status`, `from`, `to` |
| GET/PUT | `/api/segments/rules`, GET `/api/segments` | Admin |
| GET/PUT | `/api/loyalty/settings`, POST `/api/loyalty/points/:customerId/adjustment` | Admin |
| GET | `/api/loyalty/points/me`, `/api/loyalty/rewards`, `/api/loyalty/vouchers/me` | Customer |
| POST/PATCH | `/api/loyalty/rewards` | Admin |
| POST | `/api/loyalty/rewards/:id/redeem` | Customer |
| GET | `/api/loyalty/redemptions/me` | Customer |
| GET | `/api/loyalty/redemptions` | Admin |
| PATCH | `/api/loyalty/redemptions/:id/claim` | Admin |
| GET/POST/PATCH | `/api/campaigns`, POST `/api/campaigns/:id/vouchers`, GET `/api/campaigns/:id/report` | Login; perubahan admin |

Pembelian dan pemberian poin dicatat dalam satu transaksi database, dengan constraint unik agar poin transaksi tidak dapat dicatat dua kali. Penukaran reward mengunci saldo dan stok selama proses, menghasilkan kode klaim unik untuk customer, dan muncul di daftar penukaran admin sampai ditandai sudah diserahkan. Keluhan menyimpan setiap perubahan status ke riwayat.
Admin dapat menerbitkan voucher untuk snapshot audiens kampanye. Voucher divalidasi dan ditandai terpakai saat transaksi dicatat; transaksi tersebut membawa diskon, tautan kampanye, dan data laporan.

## Definisi RFM dan customer value

Perhitungan RFM berada di `src/utils/rfm.js`; pengambilan metrik yang dipakai
bersama oleh dashboard dan endpoint segmentasi berada di
`src/services/rfm-customers.js`.

- **Populasi transaksi:** hanya transaksi dengan `status = 'completed'`.
  Penghitungan memakai satu baris transaksi unik; transaksi `void` dan transaksi
  di luar jendela evaluasi tidak menaikkan Frequency atau Monetary RFM.
- **Waktu evaluasi:** waktu server saat permintaan diterima. Timestamp database
  dikirim dan dibaca melalui koneksi UTC. Jendela Frequency dan Monetary adalah
  365 x 24 jam sebelum waktu evaluasi, sampai waktu evaluasi.
- **Recency (R):** jumlah hari penuh sejak transaksi selesai terakhir, dihitung
  dari waktu evaluasi UTC dan dibatasi minimum nol. Skor: 5 untuk 0–14 hari,
  4 untuk 15–30, 3 untuk 31–60, 2 untuk 61–90, dan 1 untuk lebih dari 90 hari.
- **Frequency (F):** banyak transaksi selesai unik dalam jendela 365 hari.
  **Monetary (M):** jumlah `transactions.total_amount` dari transaksi selesai
  dalam jendela yang sama. Nilai ini merupakan nominal setelah diskon voucher,
  sehingga `transaction_items.line_total` tidak dijumlahkan lagi dan diskon
  tidak dihitung dua kali.
- **Skor F dan M:** kuintil cohort pelanggan yang memiliki setidaknya satu
  transaksi selesai dalam jendela evaluasi. Skor 1 berarti kuintil terendah dan
  5 tertinggi. Nilai yang sama berbagi skor menggunakan peringkat rata-rata;
  bila semua nilai sama, skornya netral (3). Pelanggan yang belum bertransaksi
  dalam jendela mendapat skor F/M 1.
- **No Purchase:** pelanggan tanpa transaksi selesai seumur hidup. Skornya
  `111` dan Recency tidak tersedia. Kategori ini diprioritaskan lebih dahulu.

Urutan klasifikasi setelah `no_purchase` mencegah satu pelanggan menerima
beberapa segmen:

| Prioritas | Segmen | Aturan |
|---|---|---|
| 1 | `champions` | R ≥ 4, F ≥ 4, M ≥ 4 |
| 2 | `loyal_customers` | R ≥ 3 dan F ≥ 4 |
| 3 | `cant_lose_them` | R ≤ 2, minimal 6 transaksi selesai seumur hidup, dan belanja bersih seumur hidup minimal Rp750.000 |
| 4 | `at_risk` | R ≤ 2 dan minimal 4 transaksi selesai seumur hidup |
| 5 | `hibernating` | R ≤ 2, tetapi belum memenuhi aturan `at_risk` |
| 6 | `potential_loyalists` | R ≥ 4, minimal 2 transaksi di jendela, dan F ≤ 3 |
| 7 | `new_customers` | R ≥ 4 dan tepat 1 transaksi selesai seumur hidup, yang termasuk dalam jendela |
| 8 | `need_attention` | R = 3 dan F ≥ 2 |
| 9 | `regular` | Pelanggan lain yang pernah bertransaksi |

Ambang 6 transaksi dan Rp750.000 untuk `cant_lose_them` mempertahankan batas
skor tinggi yang telah ada pada aturan Frequency dan Monetary sebelumnya.
`at_risk` menggunakan ambang 4 transaksi seumur hidup agar pelanggan yang
sebelumnya aktif tetap terdeteksi walau Frequency/Monetary periode kini nol.

`customer_value` berbeda dari Monetary RFM: nilainya adalah total
`total_amount` transaksi selesai seumur hidup (net setelah diskon), dengan
kategori low < Rp250.000, medium Rp250.000–<Rp500.000, dan high ≥ Rp500.000.
Ini adalah total belanja historis, bukan rata-rata transaksi atau poin loyalty.

Poin loyalty tetap dihitung terpisah dari RFM berdasarkan nilai transaksi net
dan aturan `points_per_10000`. Sesuai keputusan bisnis, tier loyalty saat ini
tetap berdasarkan jumlah transaksi selesai: Bronze 1–4, Silver 5–9, Gold
10–19, dan Platinum ≥20. Poin tidak mengubah tier maupun skor RFM secara
otomatis. Transaksi yang dicatat admin secara eksplisit berstatus `completed`;
pengubahan status manual menjadi `void` di luar API tidak membatalkan poin yang
sudah diberikan dan memerlukan penyesuaian ledger secara terpisah.

## Contoh alur uji

1. Daftarkan customer: `POST /api/auth/register` dengan JSON `{"name":"Pelanggan Uji","phone":"08123456780","email":"uji@example.com","password":"PasswordUji123"}`.
2. Login admin/customer ke `POST /api/auth/login` menggunakan `{"identifier":"08123456789","password":"..."}`; gunakan token respons sebagai Bearer token.
3. Sebagai admin, buat produk melalui `POST /api/products`, lalu catat transaksi melalui `POST /api/transactions` dengan `{"customer_id":1,"items":[{"product_id":1,"quantity":2}]}`.
4. Verifikasi `/api/dashboard`, `/api/segments`, serta `/api/loyalty/points/me` dengan token role yang sesuai.
5. Sebagai customer, kirim keluhan di `POST /api/complaints`; sebagai admin, ubah status dengan `PATCH /api/complaints/:id/status`.

Gunakan alamat API yang dapat dijangkau perangkat saat pengujian Flutter (contohnya alamat IP LAN komputer; `localhost` pada emulator/perangkat mengarah ke perangkat itu sendiri). Untuk deployment, gunakan HTTPS, secret yang dikelola di luar source control, dan batasi CORS ke origin yang memang diperlukan.
