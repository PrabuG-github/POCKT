package main

import (
	"context"
	"log"
	"pockt/internal/db"
)

func main() {
	log.Println("Starting data cleanup tool...")

	ctx := context.Background()

	// 1. Initialize Database using the standard project logic (reads from .env)
	pool, err := db.InitPool(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize database pool: %v", err)
	}
	defer pool.Close()

	// 2. Clear data from tables (ordering matters due to foreign keys)
	log.Println("Clearing shop_products, products, and shops tables...")

	queries := []string{
		"TRUNCATE TABLE shop_products CASCADE",
		"TRUNCATE TABLE products CASCADE",
		"TRUNCATE TABLE shops CASCADE",
	}

	for _, query := range queries {
		_, err := pool.Exec(ctx, query)
		if err != nil {
			log.Fatalf("Failed to execute cleanup query (%s): %v", query, err)
		}
	}

	log.Println("Data cleanup successful!")
}
