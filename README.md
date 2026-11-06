# cd /d "C:\Users\user\Downloads\kopiers" && start "Kopiers API" cmd /k "cd /d kopiers_api && npm run dev" && start "Kopiers Admin" cmd /k "cd /d kopiers_admin && flutter pub get && flutter run -d chrome --web-port 5001 --dart-define=API_BASE_URL=http://localhost:3000/api" && start "Kopiers Customer" cmd /k "cd /d kopiers_customer && flutter pub get && flutter run -d chrome --web-port 5002 --dart-define=API_BASE_URL=http://localhost:3000/api"
# Kopiers CRM

Satu aplikasi Flutter dengan satu halaman login. Backend mengembalikan role
akun; role `admin` membuka dashboard Admin, role `customer` membuka dashboard
Customer. API Node.js dan MySQL tetap menjadi service terpisah dari Flutter.

## Struktur proyek

```text
kopiers/
├── lib/
│   ├── main.dart                 # Entry point Flutter yang ringkas
│   ├── app.dart                  # Tema, session gate, dan pemetaan role
│   ├── services/api_client.dart  # API client bersama untuk semua role
│   ├── admin/                    # Login dan fitur Admin per modul
│   └── customer/                # Fitur Customer per modul
├── kopiers_api/                 # Backend Node.js/Express dan skema database
├── android/                     # Project Android aplikasi tunggal
└── web/                         # Shell aplikasi Flutter Web
```

Data database tidak dipindah atau diubah oleh perubahan struktur ini.

## Persiapan lokal (Windows)

1. Jalankan MySQL dari XAMPP. Gunakan database `db_crm_kopiers_v2` dan skema
   `kopiers_api/database/schema.sql`. Database lama `db_crm_kopiers` tidak
   diubah.
2. Buat `kopiers_api\.env` jika belum ada:

   ```cmd
   cd /d "C:\Users\user\Downloads\kopiers\kopiers_api"
   copy .env.example .env
   ```

   Atur koneksi MySQL, `DB_NAME=db_crm_kopiers_v2`, secret JWT acak minimal 32
   karakter, dan `FRONTEND_ORIGINS=http://localhost:5001`.
3. Install dependency backend dan siapkan akun Admin jika belum ada:

   ```cmd
   cd /d "C:\Users\user\Downloads\kopiers\kopiers_api"
   npm install
   npm run create-admin -- "Admin Kopiers" 08123456789 admin@kopiers.local "GantiPasswordYangKuat"
   ```

   Jika nomor telepon sudah terdaftar, akun tersebut sudah ada; jangan
   jalankan perintah berulang. Gunakan kredensial yang memang dibuat untuk
   akun tersebut.

## Menjalankan aplikasi

Buka **dua CMD**. Pastikan MySQL XAMPP aktif.

**CMD 1 — backend API:**

```cmd
cd /d "C:\Users\user\Downloads\kopiers\kopiers_api"
npm run dev
```

Pastikan `http://localhost:3000/api/health` merespons `{"status":"ok"}`.

**CMD 2 — satu aplikasi Admin + Customer:**

```cmd
cd /d "C:\Users\user\Downloads\kopiers"
flutter pub get
flutter run -d chrome --web-port 5001 --dart-define=API_BASE_URL=http://localhost:3000/api
```

Buka satu alamat: **http://localhost:5001**. Login Admin diarahkan ke dashboard
Admin, sementara login Customer atau pendaftaran baru diarahkan ke dashboard
Customer. Biarkan kedua CMD tetap terbuka; hentikan app dengan `Ctrl+C` pada
CMD kedua.

Kartu member dapat dicetak sebagai PDF ukuran kartu standar (CR80) di atas
kertas A4. Admin memilih pelanggan lalu menekan **Cetak kartu member** pada
detailnya; Customer membuka menu loyalty dan menekan tombol yang sama. QR di
kartu memakai format member yang dapat dipindai Admin saat membuat transaksi.

Alamat API juga dapat diganti tanpa mengubah kode: dari layar login, tekan ikon
server, pilih preset USB/Wi-Fi/Emulator atau masukkan Base API URL, lalu tekan
**Simpan**. Untuk koneksi Wi-Fi, ganti IP contoh dengan IP komputer yang
menjalankan API.
Untuk Android Emulator, jalankan aplikasi dari root yang sama dengan:

```cmd
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

## Validasi

```cmd
flutter test
flutter analyze
cd /d "C:\Users\user\Downloads\kopiers\kopiers_api"
npm test
```

Tes integrasi database hanya dijalankan setelah database pengujian terisolasi
disiapkan; jangan arahkan tes integrasi ke database berisi data penting.
