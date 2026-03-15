package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

type Shop struct {
	Name           string
	Description    string
	BuildingNumber string
	Address        string
	Pincode        string
	City           string
	State          string
	Country        string
	Lat            float64
	Lng            float64
}

type Product struct {
	Name     string
	Category string
	Price    float64
	ImageURL string
}

func main() {
	if err := godotenv.Load("../../.env"); err != nil {
		log.Println("No .env file found at ../../.env")
	}

	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		log.Fatal("DATABASE_URL not set")
	}

	ctx := context.Background()
	pool, err := pgxpool.New(ctx, connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()

	shops := []Shop{
		{
			Name:           "Nilgiris Supermarket",
			Description:    "Fresh groceries and daily essentials",
			BuildingNumber: "12",
			Address:        "South Boag Road, T. Nagar",
			Pincode:        "600017",
			City:           "Chennai",
			State:          "Tamil Nadu",
			Country:        "India",
			Lat:            13.0418,
			Lng:            80.2341,
		},
		{
			Name:           "Apollo Pharmacy",
			Description:    "24/7 Pharmacy and healthcare products",
			BuildingNumber: "45",
			Address:        "Kasturba Nagar, Adyar",
			Pincode:        "600020",
			City:           "Chennai",
			State:          "Tamil Nadu",
			Country:        "India",
			Lat:            13.0033,
			Lng:            80.2550,
		},
		{
			Name:           "Starbucks Coffee",
			Description:    "Premium coffee and snacks",
			BuildingNumber: "102",
			Address:        "Phoenix Marketcity, Velachery",
			Pincode:        "600042",
			City:           "Chennai",
			State:          "Tamil Nadu",
			Country:        "India",
			Lat:            12.9815,
			Lng:            80.2184,
		},
		{
			Name:           "Mylapore Hardware",
			Description:    "Tools, hardware and home improvement",
			BuildingNumber: "8",
			Address:        "Luz Church Road, Mylapore",
			Pincode:        "600004",
			City:           "Chennai",
			State:          "Tamil Nadu",
			Country:        "India",
			Lat:            13.0333,
			Lng:            80.2667,
		},
		{
			Name:           "Reliance Digital",
			Description:    "Latest electronics and home appliances",
			BuildingNumber: "22",
			Address:        "2nd Avenue, Anna Nagar",
			Pincode:        "600040",
			City:           "Chennai",
			State:          "Tamil Nadu",
			Country:        "India",
			Lat:            13.0850,
			Lng:            80.2101,
		},
	}

	shopProducts := map[string][]Product{
		"Nilgiris Supermarket": {
			{Name: "Fresh Milk", Category: "Dairy", Price: 30.0, ImageURL: "https://images.unsplash.com/photo-1563636619-e9107da8a1bb"},
			{Name: "Whole Wheat Bread", Category: "Bakery", Price: 45.0, ImageURL: "https://images.unsplash.com/photo-1509440159596-0249088772ff"},
		},
		"Apollo Pharmacy": {
			{Name: "Paracetamol", Category: "Medicines", Price: 20.0, ImageURL: "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae"},
			{Name: "Hand Sanitizer", Category: "Healthcare", Price: 50.0, ImageURL: "https://images.unsplash.com/photo-1584622650111-993a426fbf0a"},
		},
		"Starbucks Coffee": {
			{Name: "Sumatra Coffee Beans", Category: "Beverages", Price: 850.0, ImageURL: "https://images.unsplash.com/photo-1559056199-641a0ac8b55e"},
			{Name: "Blueberry Muffin", Category: "Snacks", Price: 180.0, ImageURL: "https://images.unsplash.com/photo-1558401391-7899b4bd5bbf"},
		},
		"Mylapore Hardware": {
			{Name: "Claw Hammer", Category: "Tools", Price: 250.0, ImageURL: "https://images.unsplash.com/photo-1586864387917-f538356ef195"},
			{Name: "Steel Screws Set", Category: "Hardware", Price: 120.0, ImageURL: "https://images.unsplash.com/photo-1581244277943-fe4a9c777189"},
		},
		"Reliance Digital": {
			{Name: "Smart Phone X1", Category: "Electronics", Price: 45000.0, ImageURL: "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9"},
			{Name: "Wireless Headphones", Category: "Audio", Price: 4500.0, ImageURL: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e"},
		},
	}

	for _, s := range shops {
		var shopID string
		point := fmt.Sprintf("POINT(%f %f)", s.Lng, s.Lat)
		
		// Try to find existing shop by name
		err := pool.QueryRow(ctx, "SELECT id FROM shops WHERE name = $1", s.Name).Scan(&shopID)
		if err != nil {
			// Not found or other error, try to insert
			err = pool.QueryRow(ctx, `
				INSERT INTO shops (name, description, building_number, address, pincode, city, state, country, location)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8, ST_GeogFromText($9))
				RETURNING id`,
				s.Name, s.Description, s.BuildingNumber, s.Address, s.Pincode, s.City, s.State, s.Country, point).Scan(&shopID)
			
			if err != nil {
				log.Printf("Failed to insert shop %s: %v", s.Name, err)
				continue
			}
		} else {
			// Update existing shop location and address
			_, err = pool.Exec(ctx, `
				UPDATE shops SET location = ST_GeogFromText($1), address = $2, building_number = $3, pincode = $4, city = $5, state = $6, country = $7
				WHERE id = $8`,
				point, s.Address, s.BuildingNumber, s.Pincode, s.City, s.State, s.Country, shopID)
			if err != nil {
				log.Printf("Failed to update shop %s: %v", s.Name, err)
			}
		}

		fmt.Printf("Seeded shop: %s (ID: %s)\n", s.Name, shopID)

		for _, p := range shopProducts[s.Name] {
			var productID string
			// Product name is unique per schema.sql
			err := pool.QueryRow(ctx, `
				INSERT INTO products (name, category, image_url)
				VALUES ($1, $2, $3)
				ON CONFLICT (name) DO UPDATE SET category = EXCLUDED.category, image_url = EXCLUDED.image_url
				RETURNING id`,
				p.Name, p.Category, p.ImageURL).Scan(&productID)
			
			if err != nil {
				// Handle case where RETURNING id doesn't work on DO UPDATE (in some drivers/versions)
				err = pool.QueryRow(ctx, "SELECT id FROM products WHERE name = $1", p.Name).Scan(&productID)
				if err != nil {
					log.Printf("Failed to handle product %s: %v", p.Name, err)
					continue
				}
			}

			_, err = pool.Exec(ctx, `
				INSERT INTO shop_products (shop_id, product_id, price, stock_status)
				VALUES ($1, $2, $3, $4)
				ON CONFLICT (shop_id, product_id) DO UPDATE SET price = EXCLUDED.price`,
				shopID, productID, p.Price, "in_stock")
			if err != nil {
				log.Printf("Failed to link product %s to shop %s: %v", p.Name, s.Name, err)
			}
		}
	}

	fmt.Println("Successfully seeded Chennai shops and products!")
}
