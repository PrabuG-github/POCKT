package handler

import (
	"encoding/json"
	"log"
	"net/http"

	"pockt/internal/models"
	"pockt/internal/service"
)

type ShopHandler struct {
	svc service.ShopService
}

func NewShopHandler(svc service.ShopService) *ShopHandler {
	return &ShopHandler{svc: svc}
}

func (h *ShopHandler) AggregatePrices(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s from %s", r.Method, r.URL.Path, r.RemoteAddr)

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.BasketRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	offers, err := h.svc.AggregatePrices(r.Context(), req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(offers)
}

func (h *ShopHandler) AddProduct(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.ProductRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	productID, isUpdate, err := h.svc.AddProduct(r.Context(), req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	message := "Product added successfully"
	status := http.StatusCreated
	if isUpdate {
		message = "Product details updated (already in inventory)"
		status = http.StatusOK
	}

	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]string{
		"message":    message,
		"product_id": productID,
	})
}

func (h *ShopHandler) GetInventory(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	inventory, err := h.svc.GetInventory(r.Context())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(inventory)
}

func (h *ShopHandler) DeleteProduct(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.DeleteProductRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := h.svc.DeleteProduct(r.Context(), req.ProductID); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Product removed successfully",
	})
}

func (h *ShopHandler) UpdateProduct(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.UpdateProductRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := h.svc.UpdateProduct(r.Context(), req); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Product updated successfully",
	})
}

func (h *ShopHandler) GetSuggestions(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	resp, err := h.svc.GetSuggestions(r.Context())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func (h *ShopHandler) GetShopDetails(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	shop, err := h.svc.GetShopDetails(r.Context())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(shop)
}

func (h *ShopHandler) UpdateShop(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.Shop
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := h.svc.UpdateShop(r.Context(), req); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Shop profile updated successfully",
	})
}

func (h *ShopHandler) GetInventoryStats(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	stats, err := h.svc.GetInventoryStats(r.Context())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

// GetShopDetailsById returns full shop details including products and reviews
func (h *ShopHandler) GetShopDetailsById(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	shopID := r.URL.Query().Get("id")
	if shopID == "" {
		http.Error(w, "Missing shop ID", http.StatusBadRequest)
		return
	}

	resp, err := h.svc.GetShopDetailsById(r.Context(), shopID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// AddReview adds a new review for a shop
func (h *ShopHandler) AddReview(w http.ResponseWriter, r *http.Request) {
	log.Printf("Received %s request for %s", r.Method, r.URL.Path)

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req models.ReviewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if req.Rating < 1 || req.Rating > 5 {
		http.Error(w, "Rating must be between 1 and 5", http.StatusBadRequest)
		return
	}

	if err := h.svc.AddReview(r.Context(), req); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Review added successfully",
	})
}
