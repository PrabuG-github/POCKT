package service

import (
	"context"
	"sort"
	"strings"

	"pockt/internal/models"
	"pockt/internal/repository"
)

type ShopService interface {
	AggregatePrices(ctx context.Context, req models.BasketRequest) ([]models.ShopOffer, error)
	AddProduct(ctx context.Context, req models.ProductRequest) (string, bool, error)
	GetInventory(ctx context.Context) ([]models.InventoryItem, error)
	DeleteProduct(ctx context.Context, productID string) error
	UpdateProduct(ctx context.Context, req models.UpdateProductRequest) error
	GetSuggestions(ctx context.Context) (models.SuggestionsResponse, error)
	GetShopDetails(ctx context.Context) (models.Shop, error)
	UpdateShop(ctx context.Context, shop models.Shop) error
	GetDefaultShopID(ctx context.Context) (string, error)
	GetInventoryStats(ctx context.Context) (models.InventoryStats, error)
	// Public shop details (for shoppers viewing any shop)
	GetShopDetailsById(ctx context.Context, shopID string) (models.ShopDetailsResponse, error)
	AddReview(ctx context.Context, req models.ReviewRequest) error
}

type shopService struct {
	repo repository.ShopRepository
}

func NewShopService(repo repository.ShopRepository) ShopService {
	return &shopService{repo: repo}
}

func (s *shopService) AggregatePrices(ctx context.Context, req models.BasketRequest) ([]models.ShopOffer, error) {
	rawResults, err := s.repo.GetRawShopResults(ctx, req)
	if err != nil {
		return nil, err
	}

	// Optimization: If only searching for 1 item, return "Product View" (separate cards per product)
	// Otherwise (Basket View), group by ShopID.
	if len(req.Items) == 1 {
		offers := []models.ShopOffer{}
		reqItem := req.Items[0]

		for _, res := range rawResults {
			nameMatch := strings.Contains(strings.ToLower(res.ProductName), strings.ToLower(reqItem.Name))
			categoryMatch := strings.Contains(strings.ToLower(res.Category), strings.ToLower(reqItem.Name))

			if nameMatch || categoryMatch {
				itemTotal := res.Price * float64(reqItem.Quantity)

				offer := models.ShopOffer{
					ShopID:          res.ShopID,
					ShopName:        res.ShopName,
					Distance:        res.Distance / 1000,
					TotalPrice:      itemTotal,
					ItemsFound:      1,
					ItemsOutOfStock: 0,
					FoundItems: []models.ShopItem{
						{
							Name:       res.ProductName,
							Price:      res.Price,
							Quantity:   reqItem.Quantity,
							TotalPrice: itemTotal,
						},
					},
					MissingItems: []string{},
				}

				if res.StockStatus != "in_stock" {
					offer.ItemsOutOfStock = 1
				}

				offers = append(offers, offer)
			}
		}

		// Sort: Lowest Price first, then Distance
		sort.Slice(offers, func(i, j int) bool {
			if offers[i].TotalPrice != offers[j].TotalPrice {
				return offers[i].TotalPrice < offers[j].TotalPrice
			}
			return offers[i].Distance < offers[j].Distance
		})

		return offers, nil
	}

	shopMap := make(map[string]*models.ShopOffer)

	// Initialize ShopOffers for all shops found in raw results
	for _, res := range rawResults {
		if _, ok := shopMap[res.ShopID]; !ok {
			shopMap[res.ShopID] = &models.ShopOffer{
				ShopID:       res.ShopID,
				ShopName:     res.ShopName,
				Distance:     res.Distance / 1000,
				FoundItems:   []models.ShopItem{},
				MissingItems: []string{},
			}
		}
	}

	// 1. Process matches
	for _, res := range rawResults {
		shopOffer := shopMap[res.ShopID]

		// Check if this product matches any item in our basket
		for _, item := range req.Items {
			nameMatch := strings.Contains(strings.ToLower(res.ProductName), strings.ToLower(item.Name))
			categoryMatch := strings.Contains(strings.ToLower(res.Category), strings.ToLower(item.Name))

			// fmt.Printf("DEBUG: Checking '%s' against item '%s' -> NameMatch: %v, CatMatch: %v\n", res.ProductName, item.Name, nameMatch, categoryMatch)

			if nameMatch || categoryMatch {
				// Avoid duplicates if multiple raw results match the same basket item (simple heuristic)
				alreadyFound := false
				for _, found := range shopOffer.FoundItems {
					if found.Name == item.Name { // simplified mapping
						alreadyFound = true
						break
					}
				}

				if !alreadyFound {
					shopOffer.ItemsFound++
					if res.StockStatus != "in_stock" {
						shopOffer.ItemsOutOfStock++
					}

					itemTotal := res.Price * float64(item.Quantity)
					shopOffer.TotalPrice += itemTotal

					shopOffer.FoundItems = append(shopOffer.FoundItems, models.ShopItem{
						Name:       res.ProductName, // Store actual product name
						Price:      res.Price,
						Quantity:   item.Quantity,
						TotalPrice: itemTotal,
					})
				}
			}
		}
	}

	// 2. Identify missing items for each shop
	for _, shopOffer := range shopMap {
		for _, reqItem := range req.Items {
			found := false
			for _, foundItem := range shopOffer.FoundItems {
				// This is a weak check, ideally we'd map by ID or explicit match,
				// but for now we rely on the same "Contains" logic or just check if we found *enough* items?
				// Actually, let's just check if we found a match for this reqItem above.
				// Re-simulating the match logic here is inefficient.
				// Better approach: track matched req items per shop.
				if strings.Contains(strings.ToLower(foundItem.Name), strings.ToLower(reqItem.Name)) {
					found = true
					break
				}
			}
			if !found {
				shopOffer.MissingItems = append(shopOffer.MissingItems, reqItem.Name)
			}
		}
	}

	offers := []models.ShopOffer{}
	for _, offer := range shopMap {
		offers = append(offers, *offer)
	}

	// Sort: Most found items first, then lowest price, then distance
	sort.Slice(offers, func(i, j int) bool {
		if offers[i].ItemsFound != offers[j].ItemsFound {
			return offers[i].ItemsFound > offers[j].ItemsFound
		}
		if offers[i].TotalPrice != offers[j].TotalPrice {
			return offers[i].TotalPrice < offers[j].TotalPrice
		}
		return offers[i].Distance < offers[j].Distance
	})

	return offers, nil
}

func (s *shopService) AddProduct(ctx context.Context, req models.ProductRequest) (string, bool, error) {
	// 1. Ensure shop exists
	shopID, err := s.repo.GetDefaultShopID(ctx)
	if err != nil {
		shopID, err = s.repo.CreateDefaultShop(ctx)
		if err != nil {
			return "", false, err
		}
	}

	// 2. Ensure product exists in catalog
	productID, err := s.repo.GetProductIDByName(ctx, req.Name)
	if err != nil {
		productID, err = s.repo.CreateProduct(ctx, req.Name, req.Category, req.ImageURL)
		if err != nil {
			return "", false, err
		}
	}

	// 3. Check if already in inventory
	isUpdate, err := s.repo.IsProductInInventory(ctx, shopID, productID)
	if err != nil {
		return "", false, err
	}

	// 4. Link to shop (updates if exists due to ON CONFLICT)
	err = s.repo.LinkProductToShop(ctx, shopID, productID, req.Price, req.StockStatus)
	return productID, isUpdate, err
}

func (s *shopService) GetInventory(ctx context.Context) ([]models.InventoryItem, error) {
	shopID, err := s.repo.GetDefaultShopID(ctx)
	if err != nil {
		return []models.InventoryItem{}, nil
	}
	return s.repo.GetInventory(ctx, shopID)
}

func (s *shopService) DeleteProduct(ctx context.Context, productID string) error {
	shopID, err := s.repo.GetDefaultShopID(ctx)
	if err != nil {
		return err
	}
	return s.repo.DeleteProduct(ctx, shopID, productID)
}

func (s *shopService) UpdateProduct(ctx context.Context, req models.UpdateProductRequest) error {
	shopID, err := s.repo.GetDefaultShopID(ctx)
	if err != nil {
		return err
	}
	return s.repo.UpdateProduct(ctx, shopID, req)
}

func (s *shopService) GetSuggestions(ctx context.Context) (models.SuggestionsResponse, error) {
	return s.repo.GetSuggestions(ctx)
}

func (s *shopService) GetShopDetails(ctx context.Context) (models.Shop, error) {
	shopID, err := s.repo.GetDefaultShopID(ctx)
	if err != nil {
		return models.Shop{}, err
	}
	return s.repo.GetShopDetails(ctx, shopID)
}

func (s *shopService) UpdateShop(ctx context.Context, shop models.Shop) error {
	shopID, err := s.repo.GetDefaultShopID(ctx)
	if err != nil {
		return err
	}
	return s.repo.UpdateShop(ctx, shopID, shop)
}

func (s *shopService) GetInventoryStats(ctx context.Context) (models.InventoryStats, error) {
	shopID, err := s.repo.GetDefaultShopID(ctx)
	if err != nil {
		return models.InventoryStats{}, err
	}
	return s.repo.GetInventoryStats(ctx, shopID)
}

func (s *shopService) GetDefaultShopID(ctx context.Context) (string, error) {
	return s.repo.GetDefaultShopID(ctx)
}

func (s *shopService) GetShopDetailsById(ctx context.Context, shopID string) (models.ShopDetailsResponse, error) {
	var resp models.ShopDetailsResponse

	// Get shop details
	shop, err := s.repo.GetShopDetails(ctx, shopID)
	if err != nil {
		return resp, err
	}
	resp.Shop = shop

	// Get products
	products, err := s.repo.GetInventory(ctx, shopID)
	if err != nil {
		return resp, err
	}
	resp.Products = products

	// Get reviews
	reviews, err := s.repo.GetShopReviews(ctx, shopID)
	if err != nil {
		return resp, err
	}
	resp.Reviews = reviews

	// Get average rating
	avgRating, count, err := s.repo.GetShopAverageRating(ctx, shopID)
	if err != nil {
		return resp, err
	}
	resp.AverageRating = avgRating
	resp.ReviewCount = count

	return resp, nil
}

func (s *shopService) AddReview(ctx context.Context, req models.ReviewRequest) error {
	return s.repo.AddReview(ctx, req)
}
