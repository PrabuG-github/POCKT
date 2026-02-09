package repository

import (
	"context"
	"fmt"

	"pockt/internal/models"

	"github.com/jackc/pgx/v5/pgxpool"
)

type ShopRepository interface {
	GetRawShopResults(ctx context.Context, req models.BasketRequest) ([]RawResult, error)
	GetDefaultShopID(ctx context.Context) (string, error)
	GetShopDetails(ctx context.Context, shopID string) (models.Shop, error)
	UpdateShop(ctx context.Context, shopID string, shop models.Shop) error
	CreateDefaultShop(ctx context.Context) (string, error)
	GetProductIDByName(ctx context.Context, name string) (string, error)
	CreateProduct(ctx context.Context, name, category, imageURL string) (string, error)
	LinkProductToShop(ctx context.Context, shopID, productID string, price float64, stockStatus string) error
	GetInventory(ctx context.Context, shopID string) ([]models.InventoryItem, error)
	DeleteProduct(ctx context.Context, shopID, productID string) error
	UpdateProduct(ctx context.Context, shopID string, req models.UpdateProductRequest) error
	GetSuggestions(ctx context.Context) (models.SuggestionsResponse, error)
	GetInventoryStats(ctx context.Context, shopID string) (models.InventoryStats, error)
	IsProductInInventory(ctx context.Context, shopID, productID string) (bool, error)
	// Review methods
	GetShopReviews(ctx context.Context, shopID string) ([]models.Review, error)
	AddReview(ctx context.Context, review models.ReviewRequest) error
	GetShopAverageRating(ctx context.Context, shopID string) (float64, int, error)
}

type RawResult struct {
	ShopID      string
	ShopName    string
	Distance    float64
	ProductName string
	Price       float64
	StockStatus string
	Category    string
	ImageURL    string
}

type postgresShopRepository struct {
	db *pgxpool.Pool
}

func NewShopRepository(db *pgxpool.Pool) ShopRepository {
	return &postgresShopRepository{db: db}
}

func (r *postgresShopRepository) GetRawShopResults(ctx context.Context, req models.BasketRequest) ([]RawResult, error) {
	query := `
		SELECT 
			s.id, 
			s.name, 
			ST_Distance(s.location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) as distance,
			p.name as product_name,
			sp.price,
			sp.stock_status,
			p.category,
			COALESCE(p.image_url, '')
		FROM shops s
		JOIN shop_products sp ON s.id = sp.shop_id
		JOIN products p ON sp.product_id = p.id
		WHERE (ST_DWithin(s.location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $3 * 1000) OR $3 = 0)
	`
	rows, err := r.db.Query(ctx, query, req.UserLong, req.UserLat, req.RadiusKM)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []RawResult
	for rows.Next() {
		var res RawResult
		if err := rows.Scan(&res.ShopID, &res.ShopName, &res.Distance, &res.ProductName, &res.Price, &res.StockStatus, &res.Category, &res.ImageURL); err != nil {
			continue
		}
		results = append(results, res)
	}
	return results, nil
}

func (r *postgresShopRepository) GetShopDetails(ctx context.Context, shopID string) (models.Shop, error) {
	var s models.Shop
	query := `SELECT id, name, description, COALESCE(building_number, ''), address, COALESCE(pincode, ''), COALESCE(city, ''), COALESCE(state, ''), COALESCE(country, ''), ST_Y(location::geometry) as lat, ST_X(location::geometry) as lng FROM shops WHERE id = $1`
	err := r.db.QueryRow(ctx, query, shopID).Scan(&s.ID, &s.Name, &s.Description, &s.BuildingNumber, &s.Address, &s.Pincode, &s.City, &s.State, &s.Country, &s.Lat, &s.Lng)
	return s, err
}

func (r *postgresShopRepository) UpdateShop(ctx context.Context, shopID string, s models.Shop) error {
	query := `
		UPDATE shops 
		SET name = $1, description = $2, building_number = $3, address = $4, pincode = $5, city = $6, state = $7, country = $8, location = ST_GeogFromText($9)
		WHERE id = $10
	`
	point := fmt.Sprintf("POINT(%f %f)", s.Lng, s.Lat)
	_, err := r.db.Exec(ctx, query, s.Name, s.Description, s.BuildingNumber, s.Address, s.Pincode, s.City, s.State, s.Country, point, shopID)
	return err
}

func (r *postgresShopRepository) GetDefaultShopID(ctx context.Context) (string, error) {
	var id string
	err := r.db.QueryRow(ctx, "SELECT id FROM shops LIMIT 1").Scan(&id)
	return id, err
}

func (r *postgresShopRepository) CreateDefaultShop(ctx context.Context) (string, error) {
	var id string
	err := r.db.QueryRow(ctx, `
		INSERT INTO shops (name, description, building_number, address, pincode, city, state, country, location) 
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, ST_GeogFromText($9)) 
		RETURNING id`,
		"POCKT Demo Store", "Your trusty local grocer", "", "MG Road", "560001", "Bangalore", "Karnataka", "India", "POINT(77.5946 12.9716)",
	).Scan(&id)
	return id, err
}

func (r *postgresShopRepository) GetProductIDByName(ctx context.Context, name string) (string, error) {
	var id string
	err := r.db.QueryRow(ctx, "SELECT id FROM products WHERE LOWER(name) = LOWER($1)", name).Scan(&id)
	return id, err
}

func (r *postgresShopRepository) CreateProduct(ctx context.Context, name, category, imageURL string) (string, error) {
	var id string
	err := r.db.QueryRow(ctx, "INSERT INTO products (name, category, image_url) VALUES ($1, $2, $3) RETURNING id", name, category, imageURL).Scan(&id)
	return id, err
}

func (r *postgresShopRepository) LinkProductToShop(ctx context.Context, shopID, productID string, price float64, stockStatus string) error {
	_, err := r.db.Exec(ctx, `
		INSERT INTO shop_products (shop_id, product_id, price, stock_status)
		VALUES ($1, $2, $3, $4)
		ON CONFLICT (shop_id, product_id) 
		DO UPDATE SET price = EXCLUDED.price, stock_status = EXCLUDED.stock_status, updated_at = NOW()
	`, shopID, productID, price, stockStatus)
	return err
}

func (r *postgresShopRepository) GetInventory(ctx context.Context, shopID string) ([]models.InventoryItem, error) {
	rows, err := r.db.Query(ctx, `
		SELECT p.id, p.name, sp.price, sp.stock_status, p.category, COALESCE(p.image_url, '')
		FROM shop_products sp
		JOIN products p ON sp.product_id = p.id
		WHERE sp.shop_id = $1
		ORDER BY sp.updated_at DESC
	`, shopID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	inventory := []models.InventoryItem{}
	for rows.Next() {
		var item models.InventoryItem
		if err := rows.Scan(&item.ProductID, &item.Name, &item.Price, &item.StockStatus, &item.Category, &item.ImageURL); err != nil {
			continue
		}
		inventory = append(inventory, item)
	}
	return inventory, nil
}

func (r *postgresShopRepository) DeleteProduct(ctx context.Context, shopID, productID string) error {
	_, err := r.db.Exec(ctx, "DELETE FROM shop_products WHERE shop_id = $1 AND product_id = $2", shopID, productID)
	return err
}

func (r *postgresShopRepository) UpdateProduct(ctx context.Context, shopID string, req models.UpdateProductRequest) error {
	// 1. Update global product catalog (name/category/image)
	_, err := r.db.Exec(ctx, "UPDATE products SET name = $1, category = $2, image_url = $3 WHERE id = $4", req.Name, req.Category, req.ImageURL, req.ProductID)
	if err != nil {
		return err
	}

	// 2. Update shop-specific link (price/stock)
	_, err = r.db.Exec(ctx, "UPDATE shop_products SET price = $1, stock_status = $2, updated_at = NOW() WHERE shop_id = $3 AND product_id = $4", req.Price, req.StockStatus, shopID, req.ProductID)
	return err
}

func (r *postgresShopRepository) GetSuggestions(ctx context.Context) (models.SuggestionsResponse, error) {
	var resp models.SuggestionsResponse

	// Get unique product names
	rows, err := r.db.Query(ctx, "SELECT DISTINCT name FROM products ORDER BY name")
	if err != nil {
		return resp, err
	}
	defer rows.Close()
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err == nil {
			resp.Names = append(resp.Names, name)
		}
	}

	// Get unique categories
	rows, err = r.db.Query(ctx, "SELECT DISTINCT category FROM products ORDER BY category")
	if err != nil {
		return resp, err
	}
	defer rows.Close()
	for rows.Next() {
		var cat string
		if err := rows.Scan(&cat); err == nil {
			resp.Categories = append(resp.Categories, cat)
		}
	}

	return resp, nil
}

func (r *postgresShopRepository) IsProductInInventory(ctx context.Context, shopID, productID string) (bool, error) {
	var exists bool
	query := "SELECT EXISTS(SELECT 1 FROM shop_products WHERE shop_id = $1 AND product_id = $2)"
	err := r.db.QueryRow(ctx, query, shopID, productID).Scan(&exists)
	return exists, err
}

func (r *postgresShopRepository) GetInventoryStats(ctx context.Context, shopID string) (models.InventoryStats, error) {
	var stats models.InventoryStats

	// Get Total Items and Low Stock Items
	queryItems := `
		SELECT 
			COUNT(*),
			COUNT(*) FILTER (WHERE stock_status = 'out_of_stock' OR stock_status = 'low_stock')
		FROM shop_products 
		WHERE shop_id = $1
	`
	err := r.db.QueryRow(ctx, queryItems, shopID).Scan(&stats.TotalItems, &stats.LowStockItems)
	if err != nil {
		return stats, err
	}

	// Get Total Value
	queryValue := `
		SELECT COALESCE(SUM(price), 0)
		FROM shop_products
		WHERE shop_id = $1 AND stock_status = 'in_stock'
	`
	err = r.db.QueryRow(ctx, queryValue, shopID).Scan(&stats.TotalValue)

	return stats, err
}

func (r *postgresShopRepository) GetShopReviews(ctx context.Context, shopID string) ([]models.Review, error) {
	rows, err := r.db.Query(ctx, `
		SELECT id, shop_id, rating, COALESCE(comment, ''), username, created_at::text
		FROM reviews
		WHERE shop_id = $1
		ORDER BY created_at DESC
	`, shopID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	reviews := []models.Review{}
	for rows.Next() {
		var r models.Review
		if err := rows.Scan(&r.ID, &r.ShopID, &r.Rating, &r.Comment, &r.Username, &r.CreatedAt); err != nil {
			continue
		}
		reviews = append(reviews, r)
	}
	return reviews, nil
}

func (r *postgresShopRepository) AddReview(ctx context.Context, review models.ReviewRequest) error {
	username := review.Username
	if username == "" {
		username = "Anonymous"
	}
	_, err := r.db.Exec(ctx, `
		INSERT INTO reviews (shop_id, rating, comment, username)
		VALUES ($1, $2, $3, $4)
	`, review.ShopID, review.Rating, review.Comment, username)
	return err
}

func (r *postgresShopRepository) GetShopAverageRating(ctx context.Context, shopID string) (float64, int, error) {
	var avgRating float64
	var count int
	err := r.db.QueryRow(ctx, `
		SELECT COALESCE(AVG(rating), 0), COUNT(*)
		FROM reviews
		WHERE shop_id = $1
	`, shopID).Scan(&avgRating, &count)
	return avgRating, count, err
}
