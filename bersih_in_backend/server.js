require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();

// Middleware untuk mengizinkan CORS dan menerima JSON
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Koneksi ke Database MySQL
const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

db.connect((err) => {
    if (err) {
        console.error('Koneksi database gagal:', err);
        return;
    }
    console.log('Berhasil terhubung ke MySQL Bersih.In');
});

// ==========================================
// RUTE AKUN (LOGIN, REGISTER, DLL)
// ==========================================

// Rute pendaftaran akun baru
app.post('/api/register', async (req, res) => {
    const { email, username, password } = req.body;

    if (!email || !username || !password) {
        return res.status(400).json({ message: 'Harap lengkapi semua data' });
    }

    try {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const query = 'INSERT INTO profiles (email, username, password) VALUES (?, ?, ?)';
        db.query(query, [email, username, hashedPassword], (err, result) => {
            if (err) {
                console.error('Gagal menyimpan data:', err);
                return res.status(500).json({ message: 'Email sudah digunakan atau terjadi kesalahan server' });
            }
            res.status(201).json({ message: 'Pendaftaran berhasil' });
        });
    } catch (error) {
        console.error('Gagal memproses kata sandi:', error);
        res.status(500).json({ message: 'Terjadi kesalahan saat memproses data' });
    }
});

// Rute login akun
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Email/username dan kata sandi wajib diisi' });
    }

    // Support login dengan email ATAU username
    const query = 'SELECT * FROM profiles WHERE email = ? OR username = ?';
    db.query(query, [email, email], async (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Terjadi kesalahan pada server' });
        }

        if (results.length === 0) {
            return res.status(401).json({ message: 'Email/username tidak ditemukan' });
        }

        const user = results[0];

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: 'Kata sandi salah' });
        }

        const token = jwt.sign(
            { id: user.id, username: user.username, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: '1h' }
        );

        res.status(200).json({
            message: 'Login berhasil',
            token: token,
            user: { username: user.username, email: user.email }
        });
    });
});

// Rute mengambil data profil
app.get('/api/profile/:email', (req, res) => {
    const email = req.params.email;
    const query = 'SELECT username, email, avatar_url FROM profiles WHERE email = ?';

    db.query(query, [email], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ message: 'Terjadi kesalahan pada server' });
        }

        if (results.length === 0) {
            return res.status(404).json({ message: 'Akun tidak ditemukan' });
        }

        res.status(200).json({ user: results[0] });
    });
});

// Rute memperbarui data akun
app.put('/api/update-profile', async (req, res) => {
    const { oldEmail, email, username, password, avatar_url } = req.body;

    try {
        let query = 'UPDATE profiles SET email = ?, username = ?';
        let params = [email, username];

        // Perbarui kata sandi jika diisi
        if (password && password.trim() !== "") {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);
            query += ', password = ?';
            params.push(hashedPassword);
        }

        // Perbarui foto profil jika ada
        if (avatar_url && avatar_url.trim() !== "") {
            query += ', avatar_url = ?';
            params.push(avatar_url);
        }

        query += ' WHERE email = ?';
        params.push(oldEmail);

        db.query(query, params, (err, result) => {
            if (err) return res.status(500).json({ message: 'Gagal memperbarui data' });
            res.status(200).json({ message: 'Data berhasil diperbarui' });
        });
    } catch (e) {
        res.status(500).json({ message: 'Terjadi kesalahan saat memperbarui data' });
    }
});

// Rute menghapus akun
app.delete('/api/delete-account/:email', (req, res) => {
    const email = req.params.email;
    const query = 'DELETE FROM profiles WHERE email = ?';
    db.query(query, [email], (err, result) => {
        if (err) return res.status(500).json({ message: 'Gagal menghapus akun' });
        res.status(200).json({ message: 'Akun berhasil dihapus' });
    });
});

// Rute membatalkan pesanan
app.delete('/api/cancel-order/:orderId', (req, res) => {
    const orderId = req.params.orderId;
    const sql = "DELETE FROM orders WHERE id = ? AND status = 'menunggu_pembayaran'";
    db.query(sql, [orderId], (err, result) => {
        if (err) return res.status(500).json({ error: 'Gagal membatalkan pesanan' });
        if (result.affectedRows === 0) {
            return res.status(400).json({ error: 'Pesanan tidak ditemukan atau tidak dapat dibatalkan' });
        }
        res.status(200).json({ message: 'Pesanan berhasil dibatalkan' });
    });
});

// ==========================================
// RUTE ALAMAT TERSIMPAN
// ==========================================

// Mengambil daftar alamat
app.get('/api/get_addresses', (req, res) => {
    const username = req.query.username;

    if (!username) {
        return res.status(400).json({ error: 'Username tidak boleh kosong' });
    }

    const sql = "SELECT * FROM saved_addresses WHERE username = ? ORDER BY id DESC";
    db.query(sql, [username], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ data: results });
    });
});

// Menyimpan alamat baru
app.post('/api/save_address', (req, res) => {
    const { username, address, lat, lng, house_type, description } = req.body;

    if (!username || !address || !lat || !lng || !house_type) {
        return res.status(400).json({ error: 'Data alamat belum lengkap' });
    }

    const sql = "INSERT INTO saved_addresses (username, address, lat, lng, house_type, description) VALUES (?, ?, ?, ?, ?, ?)";
    db.query(sql, [username, address, lat, lng, house_type, description], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Alamat berhasil disimpan' });
    });
});

// Menghapus alamat
app.delete('/api/delete_address/:id', (req, res) => {
    const id = req.params.id;
    const sql = "DELETE FROM saved_addresses WHERE id = ?";
    db.query(sql, [id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Alamat berhasil dihapus' });
    });
});

// Memperbarui alamat
app.put('/api/edit_address/:id', (req, res) => {
    const id = req.params.id;
    const { address, house_type, description } = req.body;

    const sql = "UPDATE saved_addresses SET address = ?, house_type = ?, description = ? WHERE id = ?";
    db.query(sql, [address, house_type, description, id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Alamat berhasil diperbarui' });
    });
});

// ==========================================
// RUTE PESANAN
// ==========================================

// Membuat pesanan baru
app.post('/api/orders', (req, res) => {
    const {
        user_email,
        service_name,
        total_amount,
        payment_method,
        va_number,
        qris_url,
        address,
        schedule_date,
        schedule_time,
        waktu_transaksi,
        currency,       // kode mata uang: IDR/CNY/SGD/SAR
        total_converted // nilai dalam mata uang asing, null jika IDR
    } = req.body;

    const sql = "INSERT INTO orders (user_email, service_name, total_amount, currency, total_converted, payment_method, va_number, qris_url, address, schedule_date, schedule_time, waktu_transaksi, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'menunggu_pembayaran')";

    db.query(sql, [
        user_email, service_name, total_amount,
        currency || 'IDR',
        total_converted || null,
        payment_method, va_number, qris_url,
        address, schedule_date, schedule_time, waktu_transaksi
    ], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ message: 'Pesanan berhasil dibuat', orderId: result.insertId });
    });
});

// Memperbarui status pesanan
app.put('/api/orders/:id/status', (req, res) => {
    const { status } = req.body;
    const orderId = req.params.id;
    const sql = "UPDATE orders SET status = ? WHERE id = ?";

    db.query(sql, [status, orderId], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: `Status berhasil diperbarui menjadi ${status}` });
    });
});

// Mengambil daftar pesanan pengguna
app.get('/api/orders/:email', (req, res) => {
    const email = req.params.email;
    const sql = "SELECT * FROM orders WHERE user_email = ? ORDER BY created_at DESC";

    db.query(sql, [email], (err, results) => {
        if (err) return res.status(500).json({ error: 'Terjadi kesalahan pada database' });
        res.status(200).json({ data: results });
    });
});

// ==========================================
// RUTE ADMIN
// ==========================================

// Login admin
app.post('/api/admin/login', (req, res) => {
    const { username, password } = req.body;
    if (username === 'admin' && password === 'admin123') {
        res.status(200).json({ message: 'Login admin berhasil' });
    } else {
        res.status(401).json({ error: 'Username atau kata sandi admin salah' });
    }
});

// Mengambil semua pesanan untuk dashboard admin
app.get('/api/admin/orders', (req, res) => {
    const sql = "SELECT * FROM orders ORDER BY created_at DESC";
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ data: results });
    });
});

// Menghitung total pendapatan dan pesanan selesai
app.get('/api/admin/revenue', (req, res) => {
    const sql = "SELECT SUM(total_amount) as total_revenue, COUNT(id) as total_orders FROM orders WHERE status = 'selesai'";
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({
            total_revenue: results[0].total_revenue || 0,
            total_orders: results[0].total_orders || 0
        });
    });
});

// ==========================================
// RUTE EVALUASI
// ==========================================

// Menyimpan evaluasi baru
app.post('/api/evaluasi', (req, res) => {
    const { email, rating, kesan, saran } = req.body;

    if (!email || !kesan || !saran) {
        return res.status(400).json({ message: 'Harap lengkapi semua data evaluasi' });
    }

    const sql = "INSERT INTO evaluations (email, rating, kesan, saran) VALUES (?, ?, ?, ?)";
    db.query(sql, [email, rating, kesan, saran], (err, result) => {
        if (err) return res.status(500).json({ error: 'Terjadi kesalahan pada database' });
        res.status(201).json({ message: 'Evaluasi berhasil dikirim' });
    });
});

// Mengambil semua evaluasi
app.get('/api/evaluasi', (req, res) => {
    const sql = "SELECT id, email, rating, kesan, saran, created_at FROM evaluations ORDER BY created_at DESC";
    db.query(sql, (err, results) => {
        if (err) {
            console.error('Gagal mengambil data evaluasi:', err);
            return res.status(500).json({ error: 'Terjadi kesalahan pada database' });
        }
        res.status(200).json({ data: results });
    });
});

// ==========================================
// RUTE LIVE CHAT
// ==========================================

// Mengambil semua pesan untuk pengguna tertentu
app.get('/api/messages/:email', (req, res) => {
    const email = req.params.email;
    const sql = "SELECT * FROM messages WHERE user_email = ? ORDER BY created_at ASC";
    db.query(sql, [email], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ data: results });
    });
});

// Mengirim pesan baru
app.post('/api/messages', (req, res) => {
    const { user_email, sender, message } = req.body;
    if (!user_email || !sender || !message) {
        return res.status(400).json({ error: 'Data pesan tidak lengkap' });
    }
    const sql = "INSERT INTO messages (user_email, sender, message) VALUES (?, ?, ?)";
    db.query(sql, [user_email, sender, message], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ message: 'Pesan berhasil dikirim', id: result.insertId });
    });
});

// Admin: mengambil daftar semua percakapan
app.get('/api/messages/admin/rooms', (req, res) => {
    const sql = `
        SELECT m.user_email, m.message AS last_message, m.created_at,
               COUNT(CASE WHEN m.sender = 'user' THEN 1 END) AS unread_count
        FROM messages m
        INNER JOIN (
            SELECT user_email, MAX(created_at) AS max_time
            FROM messages GROUP BY user_email
        ) latest ON m.user_email = latest.user_email AND m.created_at = latest.max_time
        GROUP BY m.user_email
        ORDER BY m.created_at DESC
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ data: results });
    });
});

// ==========================================
// RUTE REVIEW TRANSAKSI (order_reviews)
// ==========================================

// Simpan review untuk pesanan tertentu
app.post('/api/order-reviews', (req, res) => {
    const { order_id, user_email, rating, review } = req.body;
    if (!order_id || !user_email || !rating || !review) {
        return res.status(400).json({ message: 'Harap lengkapi semua data ulasan' });
    }
    const sql = "INSERT INTO order_reviews (order_id, user_email, rating, review) VALUES (?, ?, ?, ?)";
    db.query(sql, [order_id, user_email, rating, review], (err, result) => {
        if (err) {
            // Duplicate key = sudah pernah review
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(409).json({ message: 'Ulasan untuk pesanan ini sudah dikirim' });
            }
            return res.status(500).json({ error: 'Terjadi kesalahan pada database' });
        }
        res.status(201).json({ message: 'Ulasan berhasil dikirim', id: result.insertId });
    });
});

// Cek apakah order sudah direview
app.get('/api/order-reviews/check/:orderId', (req, res) => {
    const orderId = req.params.orderId;
    const sql = "SELECT id, rating, review FROM order_reviews WHERE order_id = ?";
    db.query(sql, [orderId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ reviewed: results.length > 0, data: results[0] || null });
    });
});

// Ambil semua review transaksi (untuk About Us / halaman publik)
app.get('/api/order-reviews', (req, res) => {
    const sql = `
        SELECT r.id, r.order_id, r.user_email, r.rating, r.review, r.created_at,
               o.service_name
        FROM order_reviews r
        LEFT JOIN orders o ON r.order_id = o.id
        ORDER BY r.created_at DESC
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ data: results });
    });
});

// ==========================================
// RUTE ADUAN / LAPORAN (reports)
// ==========================================

// Kirim aduan baru
app.post('/api/reports', (req, res) => {
    const { order_id, user_email, description, image_base64 } = req.body;
    if (!order_id || !user_email || !description) {
        return res.status(400).json({ message: 'Harap lengkapi data laporan' });
    }
    const sql = "INSERT INTO reports (order_id, user_email, description, image_base64) VALUES (?, ?, ?, ?)";
    db.query(sql, [order_id, user_email, description, image_base64 || null], (err, result) => {
        if (err) return res.status(500).json({ error: 'Terjadi kesalahan pada database' });
        res.status(201).json({ message: 'Laporan berhasil dikirim', id: result.insertId });
    });
});

// Admin: ambil semua laporan
app.get('/api/admin/reports', (req, res) => {
    const sql = `
        SELECT r.id, r.order_id, r.user_email, r.description,
               r.image_base64, r.status, r.created_at,
               o.service_name
        FROM reports r
        LEFT JOIN orders o ON r.order_id = o.id
        ORDER BY r.created_at DESC
    `;
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ data: results });
    });
});

// Admin: update status laporan
app.put('/api/admin/reports/:id/status', (req, res) => {
    const { status } = req.body;
    const id = req.params.id;
    const sql = "UPDATE reports SET status = ? WHERE id = ?";
    db.query(sql, [status, id], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Status laporan diperbarui' });
    });
});

// ==========================================
// SERVER
// ==========================================

app.get('/', (req, res) => {
    res.send('Server Bersih.In berjalan');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server berjalan di port ${PORT}`);
});
