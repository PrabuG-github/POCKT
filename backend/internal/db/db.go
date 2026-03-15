package db

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func InitPool(ctx context.Context) (*pgxpool.Pool, error) {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, relying on system environment variables")
	}

	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		return nil, fmt.Errorf("DATABASE_URL environment variable is not set")
	}

	pool, err := pgxpool.New(ctx, connStr)
	if err != nil {
		return nil, err
	}

	var version string
	err = pool.QueryRow(ctx, "SELECT version()").Scan(&version)
	if err != nil {
		return nil, err
	}
	log.Println("Database connection established. Version:", version)

	// Ensure indexes exist for performance
	_, err = pool.Exec(ctx, `
		CREATE INDEX IF NOT EXISTS idx_products_name_prefix ON products (lower(name) text_pattern_ops);
		CREATE INDEX IF NOT EXISTS idx_products_category ON products (category);
		CREATE INDEX IF NOT EXISTS idx_shops_location ON shops USING GIST (location);
		ALTER TABLE products ADD COLUMN IF NOT EXISTS image_url TEXT;
		ALTER TABLE shops ADD COLUMN IF NOT EXISTS building_number VARCHAR(100);
		ALTER TABLE shops ADD COLUMN IF NOT EXISTS pincode VARCHAR(20);
		ALTER TABLE shops ADD COLUMN IF NOT EXISTS city VARCHAR(100);
		ALTER TABLE shops ADD COLUMN IF NOT EXISTS state VARCHAR(100);
		ALTER TABLE shops ADD COLUMN IF NOT EXISTS country VARCHAR(100);
		ALTER TABLE shops ADD COLUMN IF NOT EXISTS opening_time VARCHAR(5); -- HH:MM
		ALTER TABLE shops ADD COLUMN IF NOT EXISTS closing_time VARCHAR(5); -- HH:MM
		ALTER TABLE shops ADD COLUMN IF NOT EXISTS image_urls TEXT[];
		
		CREATE TABLE IF NOT EXISTS reviews (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			shop_id UUID REFERENCES shops(id) ON DELETE CASCADE,
			rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
			comment TEXT,
			username VARCHAR(100) NOT NULL DEFAULT 'Anonymous',
			created_at TIMESTAMP DEFAULT NOW()
		);
		CREATE INDEX IF NOT EXISTS idx_reviews_shop_id ON reviews(shop_id);
	`)
	if err != nil {
		log.Printf("Warning: Failed to create indexes: %v", err)
	} else {
		log.Println("Database indexes verified/created.")
	}

	return pool, nil
}
