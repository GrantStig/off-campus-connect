DROP DATABASE IF EXISTS offcampusconnect;
CREATE DATABASE offcampusconnect;
USE offcampusconnect;

-- UNIVERSITY
CREATE TABLE University (
    university_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    domain VARCHAR(50)
);

-- USER
CREATE TABLE User (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    user_type ENUM('student', 'landlord', 'admin') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- STUDENT PROFILE
CREATE TABLE Student_Profile (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    university_id INT,
    major VARCHAR(100),
    graduation_year INT,
    budget_min DECIMAL(10,2),
    budget_max DECIMAL(10,2),
    pets_allowed BOOLEAN DEFAULT FALSE,
    smoking_allowed BOOLEAN DEFAULT FALSE,
    bio TEXT,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE,
    FOREIGN KEY (university_id) REFERENCES University(university_id)
);

-- LANDLORD PROFILE
CREATE TABLE Landlord_Profile (
    landlord_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    company_name VARCHAR(100),
    phone VARCHAR(20),
    verified BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- PROPERTY
CREATE TABLE Property (
    property_id INT PRIMARY KEY AUTO_INCREMENT,
    landlord_id INT NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(50),
    zip VARCHAR(10),
    rent_price DECIMAL(10,2),
    bedroom_count INT,
    bathroom_count INT,
    available BOOLEAN DEFAULT TRUE,
    description TEXT,
    FOREIGN KEY (landlord_id) REFERENCES Landlord_Profile(landlord_id)
);

-- AMENITY
CREATE TABLE Amenity (
    amenity_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50)
);

-- PROPERTY AMENITY
CREATE TABLE Property_Amenity (
    property_id INT,
    amenity_id INT,
    PRIMARY KEY (property_id, amenity_id),
    FOREIGN KEY (property_id) REFERENCES Property(property_id) ON DELETE CASCADE,
    FOREIGN KEY (amenity_id) REFERENCES Amenity(amenity_id)
);

-- LEASE
CREATE TABLE Lease (
    lease_id INT PRIMARY KEY AUTO_INCREMENT,
    property_id INT NOT NULL,
    start_date DATE,
    end_date DATE,
    monthly_rent DECIMAL(10,2),
    security_deposit DECIMAL(10,2),
    utilities_included BOOLEAN DEFAULT FALSE,
    status ENUM('active','expired','pending') DEFAULT 'active',
    FOREIGN KEY (property_id) REFERENCES Property(property_id)
);

-- LEASE PARTICIPANT
CREATE TABLE Lease_Participant (
    lease_id INT,
    user_id INT,
    PRIMARY KEY (lease_id, user_id),
    FOREIGN KEY (lease_id) REFERENCES Lease(lease_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- REVIEW
CREATE TABLE Review (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    property_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    helpful_count INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (property_id) REFERENCES Property(property_id)
);

-- EXPENSE
CREATE TABLE Expense (
    expense_id INT PRIMARY KEY AUTO_INCREMENT,
    lease_id INT NOT NULL,
    description VARCHAR(255),
    total_amount DECIMAL(10,2),
    created_by INT,
    expense_date DATE,
    FOREIGN KEY (lease_id) REFERENCES Lease(lease_id),
    FOREIGN KEY (created_by) REFERENCES User(user_id)
);

-- EXPENSE SPLIT
CREATE TABLE Expense_Split (
    split_id INT PRIMARY KEY AUTO_INCREMENT,
    expense_id INT NOT NULL,
    user_id INT NOT NULL,
    amount_owed DECIMAL(10,2),
    paid BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (expense_id) REFERENCES Expense(expense_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- COMPATIBILITY SCORE
CREATE TABLE Compatibility_Score (
    score_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id_1 INT NOT NULL,
    student_id_2 INT NOT NULL,
    score DECIMAL(5,2),
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id_1) REFERENCES Student_Profile(student_id),
    FOREIGN KEY (student_id_2) REFERENCES Student_Profile(student_id)
);

-- =====================
-- SAMPLE DATA
-- =====================

INSERT INTO University VALUES
(1,'Virginia Tech','Blacksburg, VA','vt.edu'),
(2,'University of Virginia','Charlottesville, VA','virginia.edu'),
(3,'George Mason University','Fairfax, VA','gmu.edu'),
(4,'Virginia Commonwealth University','Richmond, VA','vcu.edu'),
(5,'James Madison University','Harrisonburg, VA','jmu.edu'),
(6,'Old Dominion University','Norfolk, VA','odu.edu');

INSERT INTO User (username, email, user_type) VALUES
('jsmith','jsmith@vt.edu','student'),
('ajohnson','ajohnson@vt.edu','student'),
('mwilliams','mwilliams@vt.edu','student'),
('tbrown','tbrown@vt.edu','student'),
('ljones','ljones@vt.edu','student'),
('kgarcia','kgarcia@vt.edu','student'),
('dmartinez','dmartinez@vt.edu','student'),
('sreddy','sreddy@vt.edu','student'),
('pchen','pchen@vt.edu','student'),
('nkim','nkim@vt.edu','student'),
('rwilson','rwilson@vt.edu','student'),
('emoore','emoore@vt.edu','student'),
('ctaylor','ctaylor@vt.edu','student'),
('banderson','banderson@vt.edu','student'),
('fthomas','fthomas@vt.edu','student'),
('jwang','jwang@vt.edu','student'),
('slopez','slopez@vt.edu','student'),
('dlee','dlee@vt.edu','student'),
('mharris','mharris@vt.edu','student'),
('aclark','aclark@vt.edu','student'),
('landlord1','landlord1@gmail.com','landlord'),
('landlord2','landlord2@gmail.com','landlord'),
('landlord3','landlord3@gmail.com','landlord'),
('landlord4','landlord4@gmail.com','landlord'),
('landlord5','landlord5@gmail.com','landlord'),
('admin1','admin@offcampusconnect.com','admin');

INSERT INTO Student_Profile (user_id, university_id, major, graduation_year, budget_min, budget_max, pets_allowed, smoking_allowed) VALUES
(1,1,'Computer Science',2026,600,900,0,0),
(2,1,'Engineering',2027,500,800,1,0),
(3,1,'Business',2026,700,1000,0,0),
(4,1,'Biology',2025,400,700,0,0),
(5,1,'Psychology',2027,600,850,1,0),
(6,1,'Math',2026,500,750,0,0),
(7,1,'Physics',2025,600,900,0,1),
(8,1,'Chemistry',2027,700,1000,0,0),
(9,1,'History',2026,400,650,1,0),
(10,1,'English',2025,500,800,0,0),
(11,1,'Economics',2026,600,900,0,0),
(12,1,'Political Science',2027,550,850,0,0),
(13,1,'Art',2025,400,700,1,0),
(14,1,'Music',2026,500,750,0,0),
(15,1,'Sociology',2027,600,900,0,0),
(16,2,'Computer Science',2026,650,950,0,0),
(17,3,'Business',2027,500,800,1,0),
(18,4,'Engineering',2026,600,900,0,0),
(19,5,'Biology',2025,450,700,0,0),
(20,6,'Psychology',2027,550,850,0,0);

INSERT INTO Landlord_Profile (user_id, company_name, phone, verified) VALUES
(21,'Blacksburg Rentals LLC','540-111-2222',1),
(22,'Hokie Housing Co','540-333-4444',1),
(23,'NRV Properties','540-555-6666',0),
(24,'Campus Edge Realty','540-777-8888',1),
(25,'Blue Ridge Housing','540-999-0000',1);

INSERT INTO Property (landlord_id, address, city, state, zip, rent_price, bedroom_count, bathroom_count, available, description) VALUES
(1,'123 Main St','Blacksburg','VA','24060',800,2,1,1,'Close to campus'),
(1,'456 Oak Ave','Blacksburg','VA','24060',950,3,2,1,'Spacious with parking'),
(2,'789 Elm St','Blacksburg','VA','24060',700,1,1,0,'Studio near downtown'),
(2,'321 Pine Rd','Blacksburg','VA','24060',1100,4,2,1,'Large house for groups'),
(3,'654 Maple Dr','Blacksburg','VA','24060',850,2,1,1,'Quiet neighborhood'),
(3,'987 Cedar Ln','Blacksburg','VA','24060',750,2,2,1,'Updated kitchen'),
(4,'147 Birch Blvd','Blacksburg','VA','24060',900,3,1,1,'Near bus route'),
(4,'258 Walnut Way','Blacksburg','VA','24060',1200,4,3,0,'Luxury finishes'),
(5,'369 Spruce St','Blacksburg','VA','24060',650,1,1,1,'Affordable option'),
(5,'741 Ash Ave','Blacksburg','VA','24060',875,2,2,1,'Pet friendly'),
(1,'852 Willow Ct','Blacksburg','VA','24060',925,3,2,1,'Near dining'),
(2,'963 Poplar Pl','Blacksburg','VA','24060',1050,4,2,0,'Great location'),
(3,'159 Hickory Rd','Blacksburg','VA','24060',780,2,1,1,'Recently renovated'),
(4,'357 Magnolia St','Blacksburg','VA','24060',830,2,2,1,'Washer and dryer included'),
(5,'486 Chestnut Ave','Blacksburg','VA','24060',990,3,2,1,'Large backyard'),
(1,'624 Sycamore Dr','Blacksburg','VA','24060',720,1,1,1,'Utilities included'),
(2,'735 Dogwood Ln','Blacksburg','VA','24060',860,2,1,1,'New appliances'),
(3,'846 Redwood Rd','Blacksburg','VA','24060',1150,4,3,1,'Hot tub'),
(4,'957 Cypress St','Blacksburg','VA','24060',670,1,1,0,'Near grocery store'),
(5,'264 Hemlock Way','Blacksburg','VA','24060',940,3,2,1,'Garage included');

INSERT INTO Amenity (name, category) VALUES
('WiFi','Internet'),
('Parking','Transportation'),
('Washer/Dryer','Laundry'),
('Dishwasher','Kitchen'),
('Air Conditioning','Climate'),
('Gym','Fitness'),
('Pool','Recreation'),
('Pet Friendly','Policy'),
('Utilities Included','Billing'),
('Furnished','Interior');

INSERT INTO Property_Amenity VALUES
(1,1),(1,2),(1,3),(2,1),(2,2),(2,4),(3,1),(3,5),
(4,1),(4,2),(4,3),(4,4),(5,1),(5,8),(6,1),(6,3),
(7,1),(7,2),(8,1),(8,2),(8,6),(8,7),(9,1),(9,9),
(10,1),(10,8),(11,1),(11,3),(12,1),(12,2);

INSERT INTO Lease (property_id, start_date, end_date, monthly_rent, security_deposit, utilities_included, status) VALUES
(1,'2025-08-01','2026-07-31',800,800,0,'active'),
(2,'2025-08-01','2026-07-31',950,950,0,'active'),
(3,'2024-08-01','2025-07-31',700,700,0,'expired'),
(4,'2025-08-01','2026-07-31',1100,1100,0,'active'),
(5,'2025-01-01','2025-12-31',850,850,1,'active'),
(6,'2025-08-01','2026-07-31',750,750,0,'active'),
(7,'2025-08-01','2026-07-31',900,900,0,'active'),
(8,'2024-08-01','2025-07-31',1200,1200,0,'expired'),
(9,'2025-08-01','2026-07-31',650,650,1,'active'),
(10,'2025-08-01','2026-07-31',875,875,0,'active');

INSERT INTO Lease_Participant VALUES
(1,1),(1,2),(2,3),(2,4),(3,5),(4,6),(4,7),
(5,8),(6,9),(7,10),(8,11),(9,12),(10,13),(10,14);

INSERT INTO Review (user_id, property_id, rating, comment) VALUES
(1,1,5,'Great place, very close to campus!'),
(2,2,4,'Spacious and clean, landlord is responsive'),
(3,3,3,'Decent for the price but noisy'),
(4,4,5,'Perfect for a group, lots of space'),
(5,5,4,'Quiet area, nice neighbors'),
(6,6,5,'Updated kitchen is a huge plus'),
(7,7,3,'Bus route is convenient but loud'),
(8,1,4,'Good value for money'),
(9,2,5,'Highly recommend this property'),
(10,3,2,'Had some maintenance issues'),
(11,4,4,'Great location for students'),
(12,5,5,'Very clean and well maintained'),
(13,6,4,'Landlord very helpful'),
(14,7,3,'Average experience overall'),
(15,8,5,'Luxury feel at a fair price'),
(1,9,4,'Affordable and cozy'),
(2,10,5,'Pet friendly and spacious'),
(3,11,4,'Near all the dining options'),
(4,12,3,'Good but parking is limited'),
(5,13,5,'Renovated and modern');

INSERT INTO Expense (lease_id, description, total_amount, created_by, expense_date) VALUES
(1,'Electric Bill',120.00,1,'2025-09-01'),
(1,'Internet',60.00,1,'2025-09-01'),
(2,'Water Bill',45.00,2,'2025-09-01'),
(2,'Groceries',200.00,3,'2025-09-15'),
(4,'Electric Bill',150.00,4,'2025-09-01'),
(5,'Gas Bill',80.00,5,'2025-09-01'),
(6,'Internet',60.00,6,'2025-09-01'),
(7,'Cleaning Supplies',35.00,7,'2025-09-10'),
(9,'Electric Bill',95.00,9,'2025-09-01'),
(10,'Water Bill',50.00,10,'2025-09-01');

INSERT INTO Expense_Split (expense_id, user_id, amount_owed, paid) VALUES
(1,1,60.00,1),(1,2,60.00,0),
(2,1,30.00,1),(2,2,30.00,1),
(3,3,22.50,1),(3,4,22.50,0),
(4,3,100.00,0),(4,4,100.00,0),
(5,6,75.00,1),(5,7,75.00,0),
(6,8,80.00,1),(7,9,60.00,0),
(8,10,35.00,1),(9,12,95.00,0),
(10,13,25.00,1),(10,14,25.00,0);

INSERT INTO Compatibility_Score (student_id_1, student_id_2, score) VALUES
(1,2,87.5),(1,3,72.0),(1,4,91.0),(2,3,65.5),(2,4,78.0),
(3,4,88.0),(5,6,93.0),(5,7,70.5),(6,7,82.0),(7,8,76.5),
(8,9,89.0),(9,10,67.0),(10,11,94.5),(11,12,71.0),(12,13,85.5),
(13,14,79.0),(14,15,88.5),(1,5,73.0),(2,6,90.0),(3,7,68.5);