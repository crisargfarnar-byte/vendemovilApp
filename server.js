const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const admin = require('firebase-admin');

// Initialize Firebase Admin (Needs service account JSON in production for push)
// Since we don't have the service account yet, we initialize it without credentials 
// to avoid crashes, or instruct the user to provide it later.
try {
    admin.initializeApp();
} catch(e) {
    console.log('Firebase Admin init error: ', e);
}

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json({ limit: '50mb' })); // Allow large payloads for sync

const dbPath = path.join(__dirname, 'vendemas-cloud.db');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database', err.message);
    } else {
        console.log('Connected to the SQLite database.');
        // Initialize tables based on Flutter's structure
        db.serialize(() => {
            db.run(`CREATE TABLE IF NOT EXISTS users (
                email TEXT PRIMARY KEY,
                name TEXT,
                plan TEXT,
                fcm_token TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`);
            
            db.run(`CREATE TABLE IF NOT EXISTS productos (
                id TEXT PRIMARY KEY,
                user_email TEXT,
                codigo_barras TEXT NOT NULL, 
                nombre TEXT NOT NULL,
                descripcion TEXT, 
                categoria TEXT, 
                precio_compra REAL NOT NULL DEFAULT 0,
                precio_venta REAL NOT NULL, 
                stock INTEGER NOT NULL DEFAULT 0,
                stock_minimo INTEGER NOT NULL DEFAULT 5, 
                imagen_url TEXT,
                fecha_creacion TEXT NOT NULL, 
                fecha_actualizacion TEXT NOT NULL
            )`);

            db.run(`CREATE TABLE IF NOT EXISTS ventas (
                id TEXT PRIMARY KEY, 
                user_email TEXT,
                subtotal REAL NOT NULL, 
                descuento REAL NOT NULL DEFAULT 0,
                total REAL NOT NULL, 
                metodo_pago TEXT NOT NULL, 
                monto_pagado REAL,
                vuelto REAL, 
                fecha TEXT NOT NULL, 
                nota TEXT
            )`);

            db.run(`CREATE TABLE IF NOT EXISTS items_venta (
                id TEXT PRIMARY KEY, 
                user_email TEXT,
                venta_id TEXT NOT NULL, 
                producto_id TEXT NOT NULL,
                producto_nombre TEXT NOT NULL, 
                codigo_barras TEXT, 
                precio_unitario REAL NOT NULL,
                precio_compra REAL NOT NULL DEFAULT 0, 
                cantidad INTEGER NOT NULL,
                subtotal REAL NOT NULL, 
                imagen_url TEXT
            )`);

            db.run(`CREATE TABLE IF NOT EXISTS categorias (
                id INTEGER PRIMARY KEY AUTOINCREMENT, 
                user_email TEXT,
                nombre TEXT NOT NULL
            )`);
        });
    }
});

// Middleware to extract user_email
const requireUser = (req, res, next) => {
    const userEmail = req.headers['x-user-email'];
    if (!userEmail) {
        return res.status(401).json({ error: 'Missing x-user-email header' });
    }
    req.userEmail = userEmail;
    next();
};

app.post('/api/sync/upload', requireUser, (req, res) => {
    const userEmail = req.userEmail;
    const { productos, ventas, items_venta, categorias } = req.body;

    db.serialize(() => {
        db.run('BEGIN TRANSACTION');

        // Optional: clear existing data for this user before upload to ensure full sync
        db.run(`DELETE FROM productos WHERE user_email = ?`, [userEmail]);
        db.run(`DELETE FROM ventas WHERE user_email = ?`, [userEmail]);
        db.run(`DELETE FROM items_venta WHERE user_email = ?`, [userEmail]);
        db.run(`DELETE FROM categorias WHERE user_email = ?`, [userEmail]);

        if (productos && productos.length > 0) {
            const stmt = db.prepare(`INSERT INTO productos (id, user_email, codigo_barras, nombre, descripcion, categoria, precio_compra, precio_venta, stock, stock_minimo, imagen_url, fecha_creacion, fecha_actualizacion) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);
            productos.forEach(p => stmt.run(p.id, userEmail, p.codigo_barras, p.nombre, p.descripcion, p.categoria, p.precio_compra, p.precio_venta, p.stock, p.stock_minimo, p.imagen_url, p.fecha_creacion, p.fecha_actualizacion));
            stmt.finalize();
        }

        if (ventas && ventas.length > 0) {
            const stmt = db.prepare(`INSERT INTO ventas (id, user_email, subtotal, descuento, total, metodo_pago, monto_pagado, vuelto, fecha, nota) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);
            ventas.forEach(v => stmt.run(v.id, userEmail, v.subtotal, v.descuento, v.total, v.metodo_pago, v.monto_pagado, v.vuelto, v.fecha, v.nota));
            stmt.finalize();
        }

        if (items_venta && items_venta.length > 0) {
            const stmt = db.prepare(`INSERT INTO items_venta (id, user_email, venta_id, producto_id, producto_nombre, codigo_barras, precio_unitario, precio_compra, cantidad, subtotal, imagen_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);
            items_venta.forEach(i => stmt.run(i.id, userEmail, i.venta_id, i.producto_id, i.producto_nombre, i.codigo_barras, i.precio_unitario, i.precio_compra, i.cantidad, i.subtotal, i.imagen_url));
            stmt.finalize();
        }

        if (categorias && categorias.length > 0) {
            const stmt = db.prepare(`INSERT INTO categorias (user_email, nombre) VALUES (?, ?)`);
            categorias.forEach(c => stmt.run(userEmail, c.nombre));
            stmt.finalize();
        }

        db.run('COMMIT', (err) => {
            if (err) {
                console.error(err);
                res.status(500).json({ error: 'Sync upload failed' });
            } else {
                res.json({ message: 'Sync upload successful' });
            }
        });
    });
});

app.get('/api/sync/download', requireUser, (req, res) => {
    const userEmail = req.userEmail;
    
    const result = {};
    
    db.serialize(() => {
        db.all(`SELECT * FROM productos WHERE user_email = ?`, [userEmail], (err, rows) => {
            result.productos = rows || [];
            
            db.all(`SELECT * FROM ventas WHERE user_email = ?`, [userEmail], (err, rows) => {
                result.ventas = rows || [];
                
                db.all(`SELECT * FROM items_venta WHERE user_email = ?`, [userEmail], (err, rows) => {
                    result.items_venta = rows || [];
                    
                    db.all(`SELECT * FROM categorias WHERE user_email = ?`, [userEmail], (err, rows) => {
                        result.categorias = rows || [];
                        res.json(result);
                    });
                });
            });
        });
    });
});

app.delete('/api/sync/delete', requireUser, (req, res) => {
    const userEmail = req.userEmail;

    db.serialize(() => {
        db.run('BEGIN TRANSACTION');
        db.run(`DELETE FROM productos WHERE user_email = ?`, [userEmail]);
        db.run(`DELETE FROM ventas WHERE user_email = ?`, [userEmail]);
        db.run(`DELETE FROM items_venta WHERE user_email = ?`, [userEmail]);
        db.run(`DELETE FROM categorias WHERE user_email = ?`, [userEmail]);
        db.run('COMMIT', (err) => {
            if (err) {
                console.error(err);
                res.status(500).json({ error: 'Delete failed' });
            } else {
                res.json({ message: 'User data deleted successfully' });
            }
        });
    });
});

app.post('/api/user/token', requireUser, (req, res) => {
    const userEmail = req.userEmail;
    const { fcm_token } = req.body;
    
    if (!fcm_token) return res.status(400).json({ error: 'Missing fcm_token' });

    db.run(`INSERT INTO users (email, fcm_token) VALUES (?, ?) 
            ON CONFLICT(email) DO UPDATE SET fcm_token = excluded.fcm_token`, 
    [userEmail, fcm_token], (err) => {
        if (err) {
            console.error('Error saving FCM token:', err);
            res.status(500).json({ error: 'Failed to save token' });
        } else {
            res.json({ message: 'FCM Token saved successfully' });
        }
    });
});

// Example route to trigger a push notification to a specific user
app.post('/api/user/notify', async (req, res) => {
    const { email, title, body } = req.body;
    if (!email || !title || !body) return res.status(400).json({ error: 'Missing fields' });

    db.get(`SELECT fcm_token FROM users WHERE email = ?`, [email], async (err, row) => {
        if (err || !row || !row.fcm_token) {
            return res.status(404).json({ error: 'User or token not found' });
        }
        try {
            const message = {
                notification: { title, body },
                token: row.fcm_token
            };
            const response = await admin.messaging().send(message);
            res.json({ message: 'Push sent', response });
        } catch (error) {
            console.error('Error sending push:', error);
            res.status(500).json({ error: 'Failed to send push' });
        }
    });
});

app.listen(port, () => {
    console.log(`VendeMovil Backend listening on port ${port}`);
});
