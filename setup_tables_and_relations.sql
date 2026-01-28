-- ============================================
-- VIEW AND INSPECT THE MAIN TABLE
-- ============================================

-- View the structure of the carsale1 table
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'carsale1'
ORDER BY ordinal_position;

-- View the first few rows
SELECT * FROM carsale1 LIMIT 10;

-- Count total records
SELECT COUNT(*) as total_records FROM carsale1;

-- ============================================
-- CREATE LOOKUP TABLES (DIMENSION TABLES)
-- ============================================

-- Create Make table
CREATE TABLE IF NOT EXISTS make (
    make_id SERIAL PRIMARY KEY,
    make_name VARCHAR(100) UNIQUE NOT NULL
);

-- Populate Make table from carsale1
INSERT INTO make (make_name)
SELECT DISTINCT "Make" FROM carsale1
WHERE "Make" IS NOT NULL AND "Make" != ''
ON CONFLICT (make_name) DO NOTHING;

-- Create FuelType table
CREATE TABLE IF NOT EXISTS fuel_type (
    fuel_type_id SERIAL PRIMARY KEY,
    fuel_type_name VARCHAR(50) UNIQUE NOT NULL
);

-- Populate FuelType table
INSERT INTO fuel_type (fuel_type_name)
SELECT DISTINCT "fuelType" FROM carsale1
WHERE "fuelType" IS NOT NULL AND "fuelType" != ''
ON CONFLICT (fuel_type_name) DO NOTHING;

-- Create Transmission table
CREATE TABLE IF NOT EXISTS transmission (
    transmission_id SERIAL PRIMARY KEY,
    transmission_name VARCHAR(50) UNIQUE NOT NULL
);

-- Populate Transmission table
INSERT INTO transmission (transmission_name)
SELECT DISTINCT "transmission" FROM carsale1
WHERE "transmission" IS NOT NULL AND "transmission" != ''
ON CONFLICT (transmission_name) DO NOTHING;

-- ============================================
-- CREATE NORMALIZED FACT TABLE WITH FOREIGN KEYS
-- ============================================

-- Rename old table or create new normalized table
CREATE TABLE IF NOT EXISTS car_sales_normalized (
    car_id SERIAL PRIMARY KEY,
    make_id INT REFERENCES make(make_id),
    model VARCHAR(150),
    year INT,
    price NUMERIC,
    mileage NUMERIC,
    fuel_type_id INT REFERENCES fuel_type(fuel_type_id),
    transmission_id INT REFERENCES transmission(transmission_id)
);

-- Populate the normalized table from carsale1
INSERT INTO car_sales_normalized (make_id, model, year, price, mileage, fuel_type_id, transmission_id)
SELECT 
    m.make_id,
    cs."model",
    cs."year",
    cs."price",
    cs."mileage",
    ft.fuel_type_id,
    t.transmission_id
FROM carsale1 cs
LEFT JOIN make m ON cs."Make" = m.make_name
LEFT JOIN fuel_type ft ON cs."fuelType" = ft.fuel_type_name
LEFT JOIN transmission t ON cs."transmission" = t.transmission_name;

-- ============================================
-- VERIFY RELATIONSHIPS AND DATA
-- ============================================

-- View the normalized table with joined data
SELECT 
    cs.car_id,
    m.make_name as Make,
    cs.model,
    cs.year,
    cs.price,
    ft.fuel_type_name as FuelType,
    t.transmission_name as Transmission
FROM car_sales_normalized cs
LEFT JOIN make m ON cs.make_id = m.make_id
LEFT JOIN fuel_type ft ON cs.fuel_type_id = ft.fuel_type_id
LEFT JOIN transmission t ON cs.transmission_id = t.transmission_id
LIMIT 10;

-- Count records in each table
SELECT 'make' as table_name, COUNT(*) as record_count FROM make
UNION ALL
SELECT 'fuel_type', COUNT(*) FROM fuel_type
UNION ALL
SELECT 'transmission', COUNT(*) FROM transmission
UNION ALL
SELECT 'car_sales_normalized', COUNT(*) FROM car_sales_normalized;

-- ============================================
-- USEFUL QUERIES FOR ANALYSIS
-- ============================================

-- Cars by Make
SELECT m.make_name, COUNT(*) as count
FROM car_sales_normalized cs
JOIN make m ON cs.make_id = m.make_id
GROUP BY m.make_name
ORDER BY count DESC;

-- Average price by FuelType
SELECT ft.fuel_type_name, AVG(cs.price) as avg_price
FROM car_sales_normalized cs
JOIN fuel_type ft ON cs.fuel_type_id = ft.fuel_type_id
GROUP BY ft.fuel_type_name
ORDER BY avg_price DESC;

-- Cars by Transmission
SELECT t.transmission_name, COUNT(*) as count
FROM car_sales_normalized cs
JOIN transmission t ON cs.transmission_id = t.transmission_id
GROUP BY t.transmission_name;
