const express = require('express');
const path = require('path');
const app = express();
const db = require('./db');

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, '../frontend/views'));
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, '../frontend/public')));

// Home
app.get('/', (req, res) => {
    const stats = {};
    db.query('SELECT COUNT(*) AS count FROM User', (err, r) => {
        stats.users = r ? r[0].count : 0;
        db.query('SELECT COUNT(*) AS count FROM Property', (err, r) => {
            stats.properties = r ? r[0].count : 0;
            db.query('SELECT COUNT(*) AS count FROM Review', (err, r) => {
                stats.reviews = r ? r[0].count : 0;
                res.render('home', { stats });
            });
        });
    });
});

// Properties
app.get('/properties', (req, res) => {
    const sql = `
        SELECT p.*, lp.company_name
        FROM Property p
        JOIN Landlord_Profile lp ON p.landlord_id = lp.landlord_id
        ORDER BY p.property_id
    `;
    db.query(sql, (err, properties) => {
        if (err) return res.status(500).send('Database error');
        db.query('SELECT * FROM Landlord_Profile ORDER BY company_name', (err, landlords) => {
            res.render('properties', { properties, landlords, success: req.query.success, error: req.query.error });
        });
    });
});

app.post('/properties/add', (req, res) => {
    const { landlord_id, address, city, state, zip, rent_price, bedroom_count, bathroom_count, available, description } = req.body;

    // Reset AUTO_INCREMENT to MAX(property_id)+1 so deleted IDs are reused
    db.query('SELECT COALESCE(MAX(property_id), 0) + 1 AS next_id FROM Property', (err, rows) => {
        if (err) return res.redirect('/properties?error=Failed to add property');
        db.query(`ALTER TABLE Property AUTO_INCREMENT = ${rows[0].next_id}`, (err) => {
            if (err) return res.redirect('/properties?error=Failed to add property');

            const sql = `INSERT INTO Property (landlord_id, address, city, state, zip, rent_price, bedroom_count, bathroom_count, available, description)
                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
            db.query(sql, [landlord_id, address, city, state, zip, rent_price, bedroom_count, bathroom_count, available ? 1 : 0, description], (err) => {
                if (err) return res.redirect('/properties?error=Failed to add property');
                res.redirect('/properties?success=Property added successfully');
            });
        });
    });
});

app.post('/properties/update/:id', (req, res) => {
    const { landlord_id, address, city, state, zip, rent_price, bedroom_count, bathroom_count, available, description } = req.body;
    const sql = `UPDATE Property SET landlord_id=?, address=?, city=?, state=?, zip=?, rent_price=?, bedroom_count=?, bathroom_count=?, available=?, description=?
                 WHERE property_id=?`;
    db.query(sql, [landlord_id, address, city, state, zip, rent_price, bedroom_count, bathroom_count, available ? 1 : 0, description, req.params.id], (err) => {
        if (err) return res.redirect('/properties?error=Failed to update property');
        res.redirect('/properties?success=Property updated successfully');
    });
});

app.post('/properties/delete/:id', (req, res) => {
    db.query('DELETE FROM Property_Amenity WHERE property_id = ?', [req.params.id], () => {
        db.query('DELETE FROM Review WHERE property_id = ?', [req.params.id], () => {
            db.query('SELECT lease_id FROM Lease WHERE property_id = ?', [req.params.id], (err, leases) => {
                if (leases && leases.length > 0) {
                    const leaseIds = leases.map(l => l.lease_id);
                    db.query('SELECT expense_id FROM Expense WHERE lease_id IN (?)', [leaseIds], (err, expenses) => {
                        const cleanupAndDelete = () => {
                            db.query('DELETE FROM Lease_Participant WHERE lease_id IN (?)', [leaseIds], () => {
                                db.query('DELETE FROM Lease WHERE property_id = ?', [req.params.id], () => {
                                    db.query('DELETE FROM Property WHERE property_id = ?', [req.params.id], (err) => {
                                        if (err) return res.redirect('/properties?error=Failed to delete property');
                                        res.redirect('/properties?success=Property deleted successfully');
                                    });
                                });
                            });
                        };
                        if (expenses && expenses.length > 0) {
                            const expenseIds = expenses.map(e => e.expense_id);
                            db.query('DELETE FROM Expense_Split WHERE expense_id IN (?)', [expenseIds], () => {
                                db.query('DELETE FROM Expense WHERE lease_id IN (?)', [leaseIds], () => {
                                    cleanupAndDelete();
                                });
                            });
                        } else {
                            cleanupAndDelete();
                        }
                    });
                } else {
                    db.query('DELETE FROM Property WHERE property_id = ?', [req.params.id], (err) => {
                        if (err) return res.redirect('/properties?error=Failed to delete property');
                        res.redirect('/properties?success=Property deleted successfully');
                    });
                }
            });
        });
    });
});

// Reviews

app.get('/reviews', (req, res) => {
    const sql = `
        SELECT r.*, u.username, p.address
        FROM Review r
        JOIN User u ON r.user_id = u.user_id
        JOIN Property p ON r.property_id = p.property_id
        ORDER BY r.created_date DESC
    `;
    db.query(sql, (err, reviews) => {
        if (err) return res.status(500).send('Database error');
        db.query("SELECT user_id, username FROM User WHERE user_type='student' ORDER BY username", (err, users) => {
            db.query('SELECT property_id, address FROM Property ORDER BY address', (err, properties) => {
                res.render('reviews', { reviews, users, properties, success: req.query.success, error: req.query.error });
            });
        });
    });
});

app.post('/reviews/add', (req, res) => {
    const { user_id, property_id, rating, comment } = req.body;

    // Reset AUTO_INCREMENT to MAX(review_id)+1 so deleted IDs are reused
    db.query('SELECT COALESCE(MAX(review_id), 0) + 1 AS next_id FROM Review', (err, rows) => {
        if (err) return res.redirect('/reviews?error=Failed to add review');
        db.query(`ALTER TABLE Review AUTO_INCREMENT = ${rows[0].next_id}`, (err) => {
            if (err) return res.redirect('/reviews?error=Failed to add review');

            const sql = `INSERT INTO Review (user_id, property_id, rating, comment) VALUES (?, ?, ?, ?)`;
            db.query(sql, [user_id, property_id, rating, comment], (err) => {
                if (err) return res.redirect('/reviews?error=Failed to add review');
                res.redirect('/reviews?success=Review added successfully');
            });
        });
    });
});

app.post('/reviews/update/:id', (req, res) => {
    const { rating, comment } = req.body;
    const sql = `UPDATE Review SET rating=?, comment=? WHERE review_id=?`;
    db.query(sql, [rating, comment, req.params.id], (err) => {
        if (err) return res.redirect('/reviews?error=Failed to update review');
        res.redirect('/reviews?success=Review updated successfully');
    });
});

app.post('/reviews/delete/:id', (req, res) => {
    db.query('DELETE FROM Review WHERE review_id = ?', [req.params.id], (err) => {
        if (err) return res.redirect('/reviews?error=Failed to delete review');
        res.redirect('/reviews?success=Review deleted successfully');
    });
});

//Users
app.get('/users', (req, res) => {
    const sql = `SELECT * FROM User ORDER BY user_id`;
    db.query(sql, (err, users) => {
        if (err) return res.status(500).send('Database error');
        res.render('users', { users, success: req.query.success, error: req.query.error });
    });
});

app.post('/users/add', (req, res) => {
    const { username, email, user_type } = req.body;

    // Reset AUTO_INCREMENT to MAX(user_id)+1 so deleted IDs are reused
    db.query('SELECT COALESCE(MAX(user_id), 0) + 1 AS next_id FROM User', (err, rows) => {
        if (err) return res.redirect('/users?error=Failed to add user');
        db.query(`ALTER TABLE User AUTO_INCREMENT = ${rows[0].next_id}`, (err) => {
            if (err) return res.redirect('/users?error=Failed to add user');

            const sql = `INSERT INTO User (username, email, user_type) VALUES (?, ?, ?)`;
            db.query(sql, [username, email, user_type], (err) => {
                if (err) return res.redirect('/users?error=Failed to add user (username or email may already exist)');
                res.redirect('/users?success=User added successfully');
            });
        });
    });
});

app.post('/users/update/:id', (req, res) => {
    const { username, email, user_type } = req.body;
    const sql = `UPDATE User SET username=?, email=?, user_type=? WHERE user_id=?`;
    db.query(sql, [username, email, user_type, req.params.id], (err) => {
        if (err) return res.redirect('/users?error=Failed to update user');
        res.redirect('/users?success=User updated successfully');
    });
});

app.post('/users/delete/:id', (req, res) => {
    const userId = req.params.id;
    db.query('DELETE FROM Expense_Split WHERE user_id = ?', [userId], () => {
        db.query('DELETE FROM Expense WHERE created_by = ?', [userId], () => {
            db.query('DELETE FROM Lease_Participant WHERE user_id = ?', [userId], () => {
                db.query('DELETE FROM Review WHERE user_id = ?', [userId], () => {
                    db.query('DELETE FROM User WHERE user_id = ?', [userId], (err) => {
                        if (err) return res.redirect('/users?error=Failed to delete user');
                        res.redirect('/users?success=User deleted successfully');
                    });
                });
            });
        });
    });
});

app.get('/reports', (req, res) => {
    const sql1 = `
        SELECT p.address, p.city, lp.company_name AS landlord,
               p.rent_price, p.bedroom_count, p.bathroom_count,
               COUNT(r.review_id) AS total_reviews,
               ROUND(AVG(r.rating), 2) AS avg_rating
        FROM Property p
        JOIN Landlord_Profile lp ON p.landlord_id = lp.landlord_id
        LEFT JOIN Review r ON r.property_id = p.property_id
        GROUP BY p.property_id
        ORDER BY avg_rating DESC
    `;
    const sql2 = `
        SELECT u.username AS landlord, lp.company_name,
               COUNT(p.property_id) AS total_properties,
               SUM(p.available = TRUE) AS available_units,
               ROUND(AVG(p.rent_price), 2) AS avg_rent
        FROM User u
        JOIN Landlord_Profile lp ON lp.landlord_id = u.user_id
        LEFT JOIN Property p ON p.landlord_id = u.user_id
        GROUP BY u.user_id
        ORDER BY total_properties DESC
    `;
    db.query(sql1, (err, propertyRatings) => {
        if (err) return res.status(500).send('Database error: ' + err.message);
        db.query(sql2, (err, landlordSummary) => {
            if (err) return res.status(500).send('Database error: ' + err.message);
            res.render('reports', { propertyRatings, landlordSummary });
        });
    });
});

// Compatibility
app.get('/compatibility', (req, res) => {
    // Get all students for the dropdown
    const studentsSql = `
        SELECT sp.student_id, u.username, sp.major, sp.graduation_year,
               sp.budget_min, sp.budget_max, sp.pets_allowed, sp.smoking_allowed
        FROM Student_Profile sp
        JOIN User u ON sp.user_id = u.user_id
        ORDER BY u.username
    `;
    db.query(studentsSql, (err, students) => {
        if (err) return res.status(500).send('Database error');

        const selectedId = req.query.student_id;
        if (!selectedId) {
            return res.render('compatibility', { students, selectedStudent: null, matches: [] });
        }

        const selectedStudent = students.find(s => s.student_id == selectedId);
        if (!selectedStudent) {
            return res.render('compatibility', { students, selectedStudent: null, matches: [] });
        }

        // Get matches: pull from Compatibility_Score where this student is either id_1 or id_2
        const matchesSql = `
            SELECT cs.score,
                   sp.student_id, u.username, sp.major, sp.graduation_year,
                   sp.budget_min, sp.budget_max, sp.pets_allowed, sp.smoking_allowed
            FROM Compatibility_Score cs
            JOIN Student_Profile sp
                ON sp.student_id = CASE
                    WHEN cs.student_id_1 = ? THEN cs.student_id_2
                    ELSE cs.student_id_1
                END
            JOIN User u ON sp.user_id = u.user_id
            WHERE cs.student_id_1 = ? OR cs.student_id_2 = ?
            ORDER BY cs.score DESC
        `;
        db.query(matchesSql, [selectedId, selectedId, selectedId], (err, matches) => {
            if (err) return res.status(500).send('Database error');
            res.render('compatibility', { students, selectedStudent, matches });
        });
    });
});

app.listen(3000, () => {
    console.log('Server running at http://localhost:3000');
});
