-- Optional: example SQL to create a basic table for car_sales (adjust types as needed)
CREATE TABLE IF NOT EXISTS car_sales (
    id serial PRIMARY KEY,
    -- add columns based on your CSV headers, for example:
    make text,
    model text,
    year integer,
    price numeric,
    mileage numeric,
    fuelType text,
    transmission text
);
