// internal/handler/analytics_handler.go
package handler

import (
	"net/http"
	"BackendFramework/internal/service"
	"github.com/gin-gonic/gin"
)

type AnalyticsHandler struct {
	service *service.AnalyticsService
}

func NewAnalyticsHandler() *AnalyticsHandler {
	return &AnalyticsHandler{
		service: service.NewAnalyticsService(),
	}
}

// GetUserRegistrations handles GET /api/analytics/user-registrations
func (h *AnalyticsHandler) GetUserRegistrations(c *gin.Context) {
	// You can add authentication/authorization here
	// Example: Check JWT token, validate user permissions, etc.
	
	analytics, err := h.service.GetUserRegistrationAnalytics()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to fetch analytics data",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, analytics)
}

// GetUserRegistrationsWithAuth handles authenticated requests
func (h *AnalyticsHandler) GetUserRegistrationsWithAuth(c *gin.Context) {
	// Extract user info from JWT token or session
	// userEmail := c.GetString("user_email") // From middleware
	
	// You can add user-specific analytics here if needed
	// For now, we'll return the same data
	
	analytics, err := h.service.GetUserRegistrationAnalytics()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Failed to fetch analytics data",
			"message": err.Error(),
		})
		return
	}
	response := gin.H{
		"status": "success",
		"data": analytics,
		"timestamp": gin.H{
			"generated_at": gin.H{
				"iso": gin.H{},
			},
		},
	}

	c.JSON(http.StatusOK, response)
}