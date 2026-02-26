package main

import (
	"context"
	"log"
	"net/http"

	"pockt/internal/db"
	"pockt/internal/handler"
	"pockt/internal/repository"
	"pockt/internal/service"
)

func main() {
	log.Println("Starting POCKT Enterprise Backend...")

	ctx := context.Background()

	// 1. Initialize Database
	pool, err := db.InitPool(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize database pool: %v", err)
	}
	defer pool.Close()

	// 2. Wire Dependencies (Dependency Injection)
	repo := repository.NewShopRepository(pool)
	svc := service.NewShopService(repo)
	h := handler.NewShopHandler(svc)

	// 3. Register Routes
	http.HandleFunc("/api/aggregate", h.AggregatePrices)
	http.HandleFunc("/api/products", h.AddProduct)
	http.HandleFunc("/api/inventory", h.GetInventory)
	http.HandleFunc("/api/products/delete", h.DeleteProduct)
	http.HandleFunc("/api/products/update", h.UpdateProduct)
	http.HandleFunc("/api/suggestions", h.GetSuggestions)
	http.HandleFunc("/api/shop", h.GetShopDetails)
	http.HandleFunc("/api/shop/update", h.UpdateShop)
	http.HandleFunc("/api/inventory/stats", h.GetInventoryStats)
	http.HandleFunc("/api/shop/details", h.GetShopDetailsById)
	http.HandleFunc("/api/shop/review", h.AddReview)

	// 4. Start Server
	log.Println("Server running on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}

}
