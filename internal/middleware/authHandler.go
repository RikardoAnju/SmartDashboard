package middleware

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"io"
	"time"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v4"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/v2/bson"

	"BackendFramework/internal/config"
	"BackendFramework/internal/database"
	"BackendFramework/internal/model"
)

var jwtSecret = []byte(config.JWT_SIGNATURE_KEY)

// Claims structure for JWT Access Toke
type AccessClaims struct {
	UserID string `json:"user_id"`
	// Role string `json:"role"`
	jwt.RegisteredClaims
}

// GenerateAccessToken generates a new JWT Access token
func GenerateAccessToken(userID string) (string, error) {
	claims := &AccessClaims{
		UserID: userID,
		// Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(config.AccessTokenExpiry)), 
			IssuedAt:  jwt.NewNumericDate(time.Now()),                    
			Issuer:"BackendFramework UIB",
		},
	}

	// Create token with claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// GenerateRefreshToken generates a new Refresh token
func GenerateRefreshToken() (string, error) {
	bytes := make([]byte, 32) // 32 bytes = 256-bit security
	_, err := rand.Read(bytes)
	if err != nil {
		return "", err
	}
	plainText := base64.StdEncoding.EncodeToString(bytes)
	key := []byte(config.ENCRYPTION_KEY) // Must be 32 bytes
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}
	nonce := make([]byte, 12) // 12 bytes for AES-GCM
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	aesGCM, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	cipherText := aesGCM.Seal(nonce, nonce, []byte(plainText), nil)
	return base64.StdEncoding.EncodeToString(cipherText), nil
}

// ValidateToken validates the JWT token and returns the claims
func ValidateToken(tokenString string) (*AccessClaims, error) {
	// Parse the token
	token, err := jwt.ParseWithClaims(tokenString, &AccessClaims{}, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	// Extract and verify claims
	claims, ok := token.Claims.(*AccessClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	var storedToken model.TokenData
	err = database.DbAuth.Collection("access_tokens").FindOne(context.TODO(), bson.M{"user_id":claims.UserID}).Decode(&storedToken)

	if err != nil || storedToken.AccessToken != tokenString || storedToken.IsValidToken == "n" {
		return nil, errors.New("Token not found or expired")
	}

	return claims, nil
}

func JWTAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusOK, gin.H{
				"code" : http.StatusUnauthorized,
				"error": "Authorization token not provided",
			})
			c.Abort()
			return
		}

		// Extract the token
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusOK, gin.H{
				"code" : http.StatusUnauthorized,
				"error": "Invalid token format",
			})
			c.Abort()
			return
		}

		token := parts[1]

		// Validate the token
		claims, err := ValidateToken(token)
		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"code" : http.StatusUnauthorized,
				"error": "Invalid or expired token",
			})
			c.Abort()
			return
		}

		// Add user information to the context
		c.Set("userID", claims.UserID)
		// c.Set("role", claims.Role)

		c.Next()
	}
}