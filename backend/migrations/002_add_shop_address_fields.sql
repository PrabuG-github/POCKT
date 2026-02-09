-- Migration to add detailed address fields to shops table
-- Run this SQL against your PostgreSQL database

ALTER TABLE shops ADD COLUMN IF NOT EXISTS building_number VARCHAR(100);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS pincode VARCHAR(20);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS state VARCHAR(100);
ALTER TABLE shops ADD COLUMN IF NOT EXISTS country VARCHAR(100);

-- Optional: Set default values for existing rows
UPDATE shops SET 
    building_number = COALESCE(building_number, ''),
    pincode = COALESCE(pincode, ''),
    city = COALESCE(city, ''),
    state = COALESCE(state, ''),
    country = COALESCE(country, '')
WHERE building_number IS NULL 
   OR pincode IS NULL 
   OR city IS NULL 
   OR state IS NULL 
   OR country IS NULL;
