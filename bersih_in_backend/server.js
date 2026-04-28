require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bcrypt = require('bcryptjs'); // Udeh gue rapihin di atas Mon
const jwt = require('jsonwebtoken');

const app = express();

// Middleware biar kaga diblokir sama aturan CORS & bisa nerima JSON
app.use(cors());
app.use(express.json()); 
app.use(express.urlencoded({ extended: true })); // ZHANGG! Tambahin ini biar bisa nangkep body dari Flutter pak

// Koneksi ke Database MySQL
const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

db.connect((err) => {
    if (err) {
        console.error('Koneksi database meledak pak:', err);
        return;
    }
    console.log('ZHANGG! Berhasil nyambung ke MySQL Bersih.In!');
});

// ==========================================
// RUTE AKUN (LOGIN, REGISTER, DLL)
// ==========================================

// RUTE BUAT REGISTER (DAFTAR) PAK
app.post('/api/register', async (req, res) => {
    const { email, username, password } = req.body;

    if (!email || !username || !password) {
        return res.status(400).json({ message: 'Isi datanye yang komplit dong Mon!' });
    }

    try {
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const query = 'INSERT INTO profiles (email, username, password) VALUES (?, ?, ?)';
        db.query(query, [email, username, hashedPassword], (err, result) => {
            if (err) {
                console.error('Error insert data:', err);
                return res.status(500).json({ message: 'Email udeh dipake atau server lagi meledak pak' });
            }
            res.status(201).json({ message: 'Berhasil daftar bos Bersih.In!' });
        });
    } catch (error) {
        console.error('Error enkripsi:', error);
        res.status(500).json({ message: 'Ada yang salah pas ngenkripsi pak' });
    }
});

// ZHANGG! INI DIA RUTE LOGIN YANG LU LUPAIN MON!
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Isi email sama passwordnye yang bener dong Mon!' });
    }

    const query = 'SELECT * FROM profiles WHERE email = ?';
    db.query(query, [email], async (err, results) => {
        if (err) {
            console.error('Database meledak:', err);
            return res.status(500).json({ message: 'Server lagi pusing pak' });
        }

        if (results.length === 0) {
            return res.status(401).json({ message: 'Email lu belom kedaftar pak!' });
        }

        const user = results[0];

        const isMatch = await bcrypt.compare(password, user.password);
        
        if (!isMatch) {
            return res.status(401).json({ message: 'Password lu salah Mon!' });
        }

        const token = jwt.sign(
            { id: user.id, username: user.username, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: '1h' } 
        );

        res.status(200).json({ 
            message: 'Berhasil masuk bos Bersih.In!',
            token: token,
            user: { username: user.username, email: user.email }
        });
    });
});

// ZHANGG! RUTE BUAT NYEDOT DATA PROFIL LIVE DARI DB PAK!
app.get('/api/profile/:email', (req, res) => {
    const email = req.params.email;
    const query = 'SELECT username, email FROM profiles WHERE email = ?';
    
    db.query(query, [email], (err, results) => {
        if (err) {
            console.error('Database meledak:', err);
            return res.status(500).json({ message: 'Server lagi pusing pak' });
        }
        
        if (results.length === 0) {
            return res.status(404).json({ message: 'Akun lu kaga nemu Mon!' });
        }
        
        res.status(200).json({ user: results[0] });
    });
});

// ZHANGG! RUTE BUAT UPDATE DATA AKUN
app.put('/api/update-profile', async (req, res) => {
    const { oldEmail, email, username, password } = req.body;

    try {
        let query = 'UPDATE profiles SET email = ?, username = ?';
        let params = [email, username];

        if (password && password.trim() !== "") {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(password, salt);
            query += ', password = ?';
            params.push(hashedPassword);
        }

        query += ' WHERE email = ?';
        params.push(oldEmail);

        db.query(query, params, (err, result) => {
            if (err) return res.status(500).json({ message: 'Gagal update data pak' });
            res.status(200).json({ message: 'ZHANGG! Data lu udeh ganteng sekarang pak!' });
        });
    } catch (e) {
        res.status(500).json({ message: 'Server lagi pusing pas update' });
    }
});

// RUTE BUAT HAPUS AKUN (HATI-HATI MON!)
app.delete('/api/delete-account/:email', (req, res) => {
    const email = req.params.email;
    const query = 'DELETE FROM profiles WHERE email = ?';
    db.query(query, [email], (err, result) => {
        if (err) return res.status(500).json({ message: 'Gagal hapus akun pak' });
        res.status(200).json({ message: 'Akun lu udeh almarhum pak!' });
    });
});

// ==========================================
// RUTE SAVED ADDRESS (TAMBAHAN BARU PAK!)
// ==========================================

// RUTE BUAT NYEDOT ALAMAT (GET)
app.get('/api/get_addresses', (req, res) => {
    const username = req.query.username;
    
    if (!username) {
        return res.status(400).json({ error: 'Username kaga boleh kosong ye Mon!' });
    }

    const sql = "SELECT * FROM saved_addresses WHERE username = ? ORDER BY id DESC";
    db.query(sql, [username], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ data: results });
    });
});

// saved address
app.post('/api/save_address', (req, res) => {
    const { username, address, lat, lng, house_type, description } = req.body;

    if (!username || !address || !lat || !lng || !house_type) {
        return res.status(400).json({ error: 'Data hunian belum lengkap pak!' });
    }

    const sql = "INSERT INTO saved_addresses (username, address, lat, lng, house_type, description) VALUES (?, ?, ?, ?, ?, ?)";
    db.query(sql, [username, address, lat, lng, house_type, description], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Alamat dan detail hunian sukses disimpen pak!' });
    });
});

// ==========================================
// RUTE BUAT HAPUS ALAMAT (DELETE)
// ==========================================
app.delete('/api/delete_address/:id', (req, res) => {
    const id = req.params.id;
    const sql = "DELETE FROM saved_addresses WHERE id = ?";
    db.query(sql, [id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Alamat lu udeh almarhum pak!' });
    });
});

// ==========================================
// RUTE BUAT EDIT ALAMAT (PUT)
// ==========================================
app.put('/api/edit_address/:id', (req, res) => {
    const id = req.params.id;
    const { address, house_type, description } = req.body; // Tambahin address di mari

    const sql = "UPDATE saved_addresses SET address = ?, house_type = ?, description = ? WHERE id = ?";
    db.query(sql, [address, house_type, description, id], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Alamat lu udeh ganteng maksimal pak!' });
    });
});

// Endpoint Buat Pesanan Baru
app.post('/api/orders', (req, res) => {
    // ZHANGG! Tambahin qris_url di mari pak!
    const { user_email, service_name, total_amount, payment_method, va_number, qris_url, address, schedule_date, schedule_time } = req.body;
    
    const sql = "INSERT INTO orders (user_email, service_name, total_amount, payment_method, va_number, qris_url, address, schedule_date, schedule_time, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'menunggu_pembayaran')";
    
    db.query(sql, [user_email, service_name, total_amount, payment_method, va_number, qris_url, address, schedule_date, schedule_time], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ message: 'Pesanan Berhasil Dibuat', orderId: result.insertId });
    });
});

// Endpoint Update Status Pesanan
app.put('/api/orders/:id/status', (req, res) => {
    const { status } = req.body;
    const orderId = req.params.id;
    const sql = "UPDATE orders SET status = ? WHERE id = ?";
    
    db.query(sql, [status, orderId], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: `Status Berhasil Diperbarui jadi ${status}` });
    });
});

// ==========================================
// RUTE AMBIL DAFTAR PESANAN USER
// ==========================================
app.get('/api/orders/:email', (req, res) => {
    const email = req.params.email;
    // ZHANGG! Kita tarik semua pesanan si user, urutin dari yang paling baru pak
    const sql = "SELECT * FROM orders WHERE user_email = ? ORDER BY created_at DESC";
    
    db.query(sql, [email], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database ngambek pak' });
        res.status(200).json({ data: results });
    });
});


// ==========================================
// FITUR ADMIN SAKTI
// ==========================================

// 1. Login Admin (1 Akun Mutlak)
app.post('/api/admin/login', (req, res) => {
    const { username, password } = req.body;
    // ZHANGG! Ganti aje pass-nye sesuai selera lu pak
    if (username === 'admin' && password === 'admin123') {
        res.status(200).json({ message: 'Login Admin Sukses' });
    } else {
        res.status(401).json({ error: 'Lu siapa mek? Kaga kenal gua!' });
    }
});

// 2. Tarik SEMUA Pesanan buat Dashboard
app.get('/api/admin/orders', (req, res) => {
    const sql = "SELECT * FROM orders ORDER BY created_at DESC";
    db.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ data: results });
    });
});

// 3. Itung Total Revenue & Pesanan Selesai
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
// SERVER JALAN
// ==========================================

// Routing dasar buat ngecek doang
app.get('/', (req, res) => {
    res.send('Server Bersih.In udeh idup Mon!');
});

// Port server lu jalan
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server udeh lari di port ${PORT} ye pak!`);
});