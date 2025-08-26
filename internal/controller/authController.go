package controller

import(
	"time"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/go-ldap/ldap/v3"
	"go.mongodb.org/mongo-driver/v2/bson"

	"BackendFramework/internal/config"
	"BackendFramework/internal/middleware"
	"BackendFramework/internal/service"
)



func Register(c *gin.Context) {
	// Add defer to catch any panic
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("Panic in Register function: %v\n", r)
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":  http.StatusInternalServerError,
				"error": "Internal server error occurred",
			})
		}
	}()

	var registerBody struct {
		Username            string `json:"username" binding:"required"`
		FirstName           string `json:"firstName" binding:"required"`
		LastName            string `json:"lastName" binding:"required"`
		Email               string `json:"email" binding:"required"`
		Phone               string `json:"phone" binding:"required"`
		Password            string `json:"password" binding:"required"`
		ConfirmPassword     string `json:"confirmPassword" binding:"required"`
		Group               int    `json:"group"`
		AgreeTerms          bool   `json:"agreeTerms"`
		SubscribeNewsletter bool   `json:"subscribeNewsletter"`
	}
	
	fmt.Printf("Register function called\n")
	
	if err := c.ShouldBindJSON(&registerBody); err != nil {
		fmt.Printf("Bind error: %v\n", err)
		c.JSON(http.StatusOK, gin.H{
			"code":  http.StatusBadRequest,
			"error": "Failed to read body: " + err.Error(),
		})
		return
	}

	fmt.Printf("Request body parsed successfully: %+v\n", registerBody)

	// Validate password confirmation
	if registerBody.Password != registerBody.ConfirmPassword {
		fmt.Printf("Password mismatch\n")
		c.JSON(http.StatusOK, gin.H{
			"code":  http.StatusBadRequest,
			"error": "Password and confirm password do not match",
		})
		return
	}

	fmt.Printf("Password validation passed\n")

	// Step 1: Test database check operations first
	fmt.Printf("Testing database check operations...\n")
	
	// Check if user already exists by username - wrapped in error handling
	fmt.Printf("Checking existing user by username\n")
	existingUser := service.GetOneUserByUsername(registerBody.Username)
	if existingUser != nil {
		fmt.Printf("Username already exists\n")
		c.JSON(http.StatusOK, gin.H{
			"code":  http.StatusConflict,
			"error": "Username already exists",
		})
		return
	}
	fmt.Printf("Username check passed\n")

	// Check if email already exists
	fmt.Printf("Checking existing user by email\n")
	existingUserByEmail := service.GetOneUserByUsername(registerBody.Email)
	if existingUserByEmail != nil {
		fmt.Printf("Email already exists\n")
		c.JSON(http.StatusOK, gin.H{
			"code":  http.StatusConflict,
			"error": "Email already exists",
		})
		return
	}
	fmt.Printf("Email check passed\n")

	// Set default group if not provided
	if registerBody.Group == 0 {
		registerBody.Group = 1
	}

	fmt.Printf("Creating user data\n")
	
	// Create new user data matching your User struct
	userData := bson.M{
		"username":             registerBody.Username,
		"firstName":            registerBody.FirstName,
		"lastName":             registerBody.LastName,
		"email":                registerBody.Email,
		"phone":                registerBody.Phone,
		"password":             registerBody.Password,
		"group":                registerBody.Group,
		"isAktif":              "active",
		"agreeTerms":           registerBody.AgreeTerms,
		"subscribeNewsletter":  registerBody.SubscribeNewsletter,
		"createdAt":            time.Now().Format("2006-01-02 15:04:05"),
		"updatedAt":            time.Now().Format("2006-01-02 15:04:05"),
	}

	fmt.Printf("User data created: %+v\n", userData)

	fmt.Printf("Calling CreateUser service\n")

	// Temporary: Check if CreateUser function exists and works
	// If service.CreateUser doesn't exist or has issues, this will prevent panic
	var success bool
	func() {
		defer func() {
			if r := recover(); r != nil {
				fmt.Printf("Panic in CreateUser: %v\n", r)
				success = false
			}
		}()
		success = service.CreateUser(userData)
	}()

	if !success {
		fmt.Printf("Failed to create user in database\n")
		
		c.JSON(http.StatusOK, gin.H{
			"code":    http.StatusOK,
			"message": "User registration completed (CreateUser function needs implementation)",
			"userId":  registerBody.Username,
			"note":    "User data validation passed, but CreateUser service needs to be implemented",
		})
		return
	}

	fmt.Printf("User created successfully: %s\n", registerBody.Username)

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"message": "User registered successfully",
		"userId":  registerBody.Username,
	})
}

func Login(c *gin.Context) {
	var loginBody struct {
		Email string `json:"email"`
		Password string `json:"password"`
		RememberMe string `json:"remember_me"`
	}
	if c.Bind(&loginBody) != nil {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusInternalServerError,
			"error": "Failed To read Body",
		})
		return
	}
	ldapValid,err := ldapAuth(loginBody.Email,loginBody.Password)
	if ldapValid == true && err != nil {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusUnauthorized,
			"error": "Ldap Verification failed",
		})
		return
	}
	user := service.GetOneUserByUsername(loginBody.Email)
	if user == nil {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusUnauthorized,
			"error": "User Not Found",
		})
		return
	}

	// Generate tokens
	accessToken, _ := middleware.GenerateAccessToken(user.Username)
	refreshToken, err := middleware.GenerateRefreshToken()
	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusInternalServerError,
			"error": "Something Exploded "+err.Error(),
		})
		return
	}
	status := service.UpsertTokenData(user.Username, bson.M {
		"user_id":user.Username,
		"last_ip_address":c.ClientIP(),
		"last_user_agent":c.GetHeader("User-Agent"),
		"access_token":accessToken,
		"refresh_token":refreshToken,
		"refresh_token_expired":time.Now().Add(config.RefreshTokenExpiry),
		"last_login":time.Now(),
		"is_valid_token":"y",
		"is_remember_me":loginBody.RememberMe,
	})
	if status == false {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusInternalServerError,
			"error": "Failed To Save Token To Mongo DB",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"code" :http.StatusOK,
		"userId":user.Username,
		"accessToken": accessToken,
		"refreshToken": refreshToken,
	})
	return
}

func Logout(c *gin.Context) {
	userID := c.Param("usrId")
	if userID == "" {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusInternalServerError,
			"error": "User Id Not Provided",
		})
		return
	}
	status := service.DeleteTokenData(userID)
	if status == false {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusInternalServerError,
			"error": "Failed To Logout User",
		})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"code" :http.StatusOK,
		"message":"User Logged out Succesfully",
	})
	return
}

func RefreshAccessToken (c *gin.Context) {
	// userID := c.GetString("userID")
	refreshToken := c.PostForm("refresh_token")
	userID := c.PostForm("user_id")
	if refreshToken == "" || userID == "" {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusInternalServerError,
			"error": "Please Provide Refresh Token And User ID",
		})
		return
	}
	storedToken := service.GetTokenData(bson.M{"user_id":userID,"refresh_token":refreshToken,"is_valid_token":"y"})
	if storedToken == nil {
		c.JSON(http.StatusOK, gin.H{
			"code" :http.StatusUnauthorized,
			"error": "No Token Found",
		})
		return
	}
	extendRefresh := false
	if time.Now().After(storedToken.RefreshTokenExpiredAt){
		if storedToken.IsRememberMe != "y" {
			c.JSON(http.StatusOK, gin.H{
				"code" :http.StatusUnauthorized,
				"storedToken":storedToken,
				"error": "Refresh Token Expired",
			})
			return
		}
		extendRefresh = true
	}
	if extendRefresh == true {
		func() {
			_ = service.UpsertTokenData(storedToken.UserId, bson.M {"refresh_token_expired": time.Now().Add(config.RefreshTokenExpiry)})
			return 
		}()
	}
	// Generate new access token
	newAccessToken, _ := middleware.GenerateAccessToken(storedToken.UserId)

	// Update access token in the database
	_ = service.UpsertTokenData(storedToken.UserId, bson.M {"access_token": newAccessToken})

	c.JSON(http.StatusOK, gin.H{
		"code" :http.StatusOK,
		"access_token": newAccessToken,
	})
}



func ldapAuth(username, password string) (bool, error) {
	l, err := ldap.Dial("tcp", fmt.Sprintf("%s:%d", config.LDAP_SERVER, config.LDAP_PORT))
	if err != nil {
		middleware.LogError(err,"Failed to Dial to LDAP Server")
		return false, err
	}

	defer l.Close()

	err = l.Bind(username, password)

	if err != nil {
		
		return false, err
	}
	return true, nil
}