-- CIS 4720 - Project 9
-- Club database

-- =====================================================
-- STEP 1. Set up the database and members
-- =====================================================

-- Show the databases.
SHOW DATABASES;

-- Create the club database.
CREATE DATABASE IF NOT EXISTS club_db;

-- Use the club database.
USE club_db;

-- Create the member table.
CREATE TABLE member (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    joined_on DATE,
    total_paid DECIMAL(7,2) DEFAULT 0.00
) AUTO_INCREMENT = 100;

-- Add Noor.
INSERT INTO member (first_name, last_name, joined_on)
VALUES ('Noor', 'Haddad', '2026-01-15');

-- Add Caleb.
INSERT INTO member (first_name, last_name, joined_on)
VALUES ('Caleb', 'Ortiz', '2026-02-03');

-- Add Sofia.
INSERT INTO member (first_name, last_name, joined_on)
VALUES ('Sofia', 'Marchetti', '2026-02-28');

-- Add Desmond.
INSERT INTO member (first_name, last_name, joined_on)
VALUES ('Desmond', 'Blake', '2026-03-11');

-- Check the members.
SELECT * FROM member;


-- =====================================================
-- STEP 2. Create the payment table
-- =====================================================

-- Create payments starting at 5000.
CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    amount DECIMAL(7,2) NOT NULL,
    paid_on DATE,
    method VARCHAR(10),
    FOREIGN KEY (member_id) REFERENCES member(member_id)
) AUTO_INCREMENT = 5000;


-- =====================================================
-- STEP 3. Create the payment log
-- =====================================================

-- Create the payment log.
CREATE TABLE payment_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT,
    amount DECIMAL(7,2),
    action VARCHAR(20),
    logged_on DATETIME
);


-- =====================================================
-- STEP 4. Check the ID counters
-- =====================================================

-- Check the next ID
SELECT table_name, auto_increment
FROM information_schema.tables
WHERE table_schema = 'club_db'
  AND table_name IN ('member', 'payment', 'payment_log')
ORDER BY table_name;


-- =====================================================
-- STEP 5. Create the member_total function
-- =====================================================

-- Add one members pay
CREATE FUNCTION member_total(p_member_id INT)
RETURNS DECIMAL(7,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    -- Store the total.
    DECLARE v_total DECIMAL(7,2);

    -- Add the payments.
    SELECT SUM(amount)
    INTO v_total
    FROM payment
    WHERE member_id = p_member_id;

    -- Return zero if empty.
    RETURN IFNULL(v_total, 0.00);
END;


-- =====================================================
-- STEP 6. Create the BEFORE INSERT trigger
-- =====================================================

-- Fill dates and fix methods.
CREATE TRIGGER trg_payment_before_insert
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
    -- Fill a missing date.
    IF NEW.paid_on IS NULL THEN
        SET NEW.paid_on = CURDATE();
    END IF;

    -- Use caps.
    SET NEW.method = UPPER(NEW.method);
END;


-- =====================================================
-- STEP 7. Create the AFTER INSERT trigger
-- =====================================================

-- Update total and log pay
CREATE TRIGGER trg_payment_after_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    -- Update this members total.
    UPDATE member
    SET total_paid = member_total(NEW.member_id)
    WHERE member_id = NEW.member_id;

    -- Log the added payment.
    INSERT INTO payment_log (member_id, amount, action, logged_on)
    VALUES (NEW.member_id, NEW.amount, 'ADDED', NOW());
END;


-- =====================================================
-- STEP 8. Create the AFTER DELETE trigger
-- =====================================================

-- Update totals and log removals.
CREATE TRIGGER trg_payment_after_delete
AFTER DELETE ON payment
FOR EACH ROW
BEGIN
    -- Update this member's total.
    UPDATE member
    SET total_paid = member_total(OLD.member_id)
    WHERE member_id = OLD.member_id;

    -- Log the removed payment.
    INSERT INTO payment_log (member_id, amount, action, logged_on)
    VALUES (OLD.member_id, OLD.amount, 'REMOVED', NOW());
END;


-- =====================================================
-- STEP 9. Test payments and the log
-- =====================================================

-- Add Noors cash payment.
INSERT INTO payment (member_id, amount, method)
VALUES (100, 45.00, 'cash');

-- Add Noors card payment.
INSERT INTO payment (member_id, amount, paid_on, method)
VALUES (100, 30.00, '2026-04-02', 'card');

-- Add Calebs check payment.
INSERT INTO payment (member_id, amount, method)
VALUES (101, 45.00, 'check');

-- Add Sofias card payment.
INSERT INTO payment (member_id, amount, paid_on, method)
VALUES (102, 60.00, '2026-03-15', 'card');

-- Check the payments.
SELECT * FROM payment;

-- Check the member totals.
SELECT * FROM member;

-- Remove Noors card payment.
DELETE FROM payment
WHERE payment_id = 5001;

-- Check Noors new total.
SELECT member_id, first_name, total_paid
FROM member
WHERE member_id = 100;

-- Check the full payment log.
SELECT * FROM payment_log;


-- =====================================================
-- STEPS 10-11. Publish to GitHub and submit the URL
-- =====================================================
