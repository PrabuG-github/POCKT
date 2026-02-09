package models

type Shop struct {
	ID             string  `json:"id"`
	Name           string  `json:"name"`
	Description    string  `json:"description"`
	BuildingNumber string  `json:"building_number"`
	Address        string  `json:"address"`
	Pincode        string  `json:"pincode"`
	City           string  `json:"city"`
	State          string  `json:"state"`
	Country        string  `json:"country"`
	Lat            float64 `json:"lat"`
	Lng            float64 `json:"lng"`
}

type BasketItem struct {
	ProductID string `json:"product_id"`
	Name      string `json:"name"`
	Quantity  int    `json:"quantity"`
}

type BasketRequest struct {
	Items    []BasketItem `json:"items"`
	RadiusKM float64      `json:"radius_km"`
	UserLat  float64      `json:"user_lat"`
	UserLong float64      `json:"user_long"`
}

type ShopOffer struct {
	ShopID          string     `json:"shop_id"`
	ShopName        string     `json:"shop_name"`
	Distance        float64    `json:"distance"`
	TotalPrice      float64    `json:"total_price"`
	ItemsFound      int        `json:"items_found"`
	ItemsOutOfStock int        `json:"items_out_of_stock"`
	FoundItems      []ShopItem `json:"found_items"`
	MissingItems    []string   `json:"missing_items"`
}

type ShopItem struct {
	Name       string  `json:"name"`
	Price      float64 `json:"price"`
	Quantity   int     `json:"quantity"`
	TotalPrice float64 `json:"total_price"`
}

type ProductRequest struct {
	Name        string  `json:"name"`
	Price       float64 `json:"price"`
	StockStatus string  `json:"stock_status"`
	Category    string  `json:"category"`
	ImageURL    string  `json:"image_url,omitempty"`
}

type InventoryItem struct {
	ProductID   string  `json:"product_id"`
	Name        string  `json:"name"`
	Price       float64 `json:"price"`
	StockStatus string  `json:"stock_status"`
	Category    string  `json:"category"`
	ImageURL    string  `json:"image_url,omitempty"`
}

type DeleteProductRequest struct {
	ProductID string `json:"product_id"`
}

type UpdateProductRequest struct {
	ProductID   string  `json:"product_id"`
	Name        string  `json:"name"`
	Price       float64 `json:"price"`
	StockStatus string  `json:"stock_status"`
	Category    string  `json:"category"`
	ImageURL    string  `json:"image_url,omitempty"`
}

type SuggestionsResponse struct {
	Names      []string `json:"names"`
	Categories []string `json:"categories"`
}

type InventoryStats struct {
	TotalItems    int     `json:"total_items"`
	LowStockItems int     `json:"low_stock_items"`
	TotalValue    float64 `json:"total_value"`
}

type Review struct {
	ID        string `json:"id"`
	ShopID    string `json:"shop_id"`
	Rating    int    `json:"rating"`
	Comment   string `json:"comment"`
	Username  string `json:"username"`
	CreatedAt string `json:"created_at"`
}

type ReviewRequest struct {
	ShopID   string `json:"shop_id"`
	Rating   int    `json:"rating"`
	Comment  string `json:"comment"`
	Username string `json:"username"`
}

type ShopDetailsResponse struct {
	Shop          Shop            `json:"shop"`
	Products      []InventoryItem `json:"products"`
	Reviews       []Review        `json:"reviews"`
	AverageRating float64         `json:"average_rating"`
	ReviewCount   int             `json:"review_count"`
}
