-- ============================================================
-- MIGRATION: Tambah kolom mata uang ke tabel orders
-- Jalankan query ini di phpMyAdmin → database bersihin_db
-- ============================================================

-- Tambah kolom currency (kode mata uang: IDR/CNY/SGD/SAR)
-- dan total_converted (nilai total dalam mata uang asing)
ALTER TABLE `orders`
  ADD COLUMN `currency` VARCHAR(10) NOT NULL DEFAULT 'IDR' AFTER `total_amount`,
  ADD COLUMN `total_converted` DECIMAL(15,4) DEFAULT NULL AFTER `currency`;

-- Verifikasi hasilnya
-- DESCRIBE `orders`;
