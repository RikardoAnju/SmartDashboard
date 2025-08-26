package middleware

import (
	"bytes"
	"io"
	"net/http"
	"context"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/v2/bson"

	"BackendFramework/internal/database"
)

func LogUserActivity() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := c.Get("userID")
		if !exists {
			userID = c.PostForm("user_id")
			// c.Next()
			// return
		}

		// Capture Query Parameters
		queryParams := c.Request.URL.Query()

		// Capture Request Body (if it's JSON)
		var requestBody map[string]interface{}
		if c.Request.Method == "POST" || c.Request.Method == "PUT" {
			bodyBytes, _ := io.ReadAll(c.Request.Body)
			c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes)) // Restore body for further processing
			if err := bson.UnmarshalExtJSON(bodyBytes, true, &requestBody); err != nil {
				requestBody = nil
			}
		}
		
		// Capture Form Data (for non-JSON POST requests)
		if requestBody == nil {
			formData := make(map[string]interface{})
			c.Request.ParseForm()
			for key, values := range c.Request.PostForm {
				if len(values) == 1 {
					formData[key] = values[0]
				} else {
					formData[key] = values
				}
			}
			requestBody = formData
		}


		logCollection := database.DbAuth.Collection("user_activity")
		// Log activity
		_, err := logCollection.InsertOne(context.TODO(), bson.M{
			"user_id":   userID,
			"endpoint":  c.Request.URL.Path,
			"method":    c.Request.Method,
			"ip_address":c.ClientIP(),
			"user_agent":c.GetHeader("User-Agent"),
			"query_params": queryParams,
			"request_body": requestBody,
			"timestamp": time.Now(),
		})

		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"code" : http.StatusUnauthorized,
				"error": "Failed To Log User Activity",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
