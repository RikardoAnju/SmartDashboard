package controller

import (
	"fmt"
	"net/http"

	"BackendFramework/internal/model"
	"BackendFramework/internal/service"
	"golang.org/x/crypto/bcrypt"
	"github.com/gin-gonic/gin"
)



func GetUsersByGroup(c *gin.Context) {
	
	group := c.Query("group")
	if group == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "Group parameter is required",
			"error":   "Group query parameter is not provided",
		})
		return
	}

	users := service.GetUsersByGroup(group)
	if users == nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "Failed to retrieve users by group",
			"error":   "Error detected. Check error log",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":      http.StatusOK,
		"message":   "Users retrieved successfully",
		"group":     group,
		"user_data": users,
	})
}

func UpdateUserInGroup(c *gin.Context) {
	// Get user ID from URL parameter
	usrId := c.Param("usrId")
	if usrId == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "User ID is required",
			"error":   "User ID parameter is not provided",
		})
		return
	}

	// Get validated input
	validatedInput, exists := c.Get("validatedInput")
	if !exists {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "Invalid input data",
			"error":   "Validated input not found",
		})
		return
	}

	userInput := validatedInput.(*model.UserInput)
	
	
	status, err := service.UpdateUserInGroup(usrId, userInput)
	if !status {
		errorMsg := "Update user in group failed"
		if err != nil {
			errorMsg = err.Error()
		}
		
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "Update user in group failed",
			"error":   errorMsg,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"message": "User updated successfully",
		"data": gin.H{
			"userId":   usrId,
			"username": userInput.Username,
		},
	})
}

func DeleteUserFromGroup(c *gin.Context) {
	
	usrId := c.Param("usrId")
	if usrId == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "User ID is required",
			"error":   "User ID parameter is not provided",
		})
		return
	}

	
	group := c.Query("group")

	
	status, err := service.DeleteUserFromGroup(usrId, group)
	if !status {
		errorMsg := "Delete user from group failed"
		if err != nil {
			errorMsg = err.Error()
		}
		
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "Delete user from group failed",
			"error":   errorMsg,
		})
		return
	}

	response := gin.H{
		"code":    http.StatusOK,
		"message": "User deleted successfully",
		"data": gin.H{
			"deletedUserId": usrId,
		},
	}

	// Add group info if provided
	if group != "" {
		response["data"].(gin.H)["group"] = group
	}

	c.JSON(http.StatusOK, response)
}

// Existing User functions

func GetUser(c *gin.Context) {
	usrId := c.Param("usrId")
	if usrId != "" {
		user := service.GetOneUser(usrId)
		if user == nil {
			c.JSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"message": "User not found",
				"error":   "User with the specified ID does not exist",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"code":      http.StatusOK,
			"message":   "User retrieved successfully",
			"user_data": user,
		})
	} else {
		users := service.GetAllUsers()
		if users == nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":    http.StatusInternalServerError,
				"message": "Failed to retrieve users",
				"error":   "Error detected. Check error log",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"code":      http.StatusOK,
			"message":   "Users retrieved successfully",
			"user_data": users,
		})
	}
}

func InsertUser(c *gin.Context) {
	validatedInput, exists := c.Get("validatedInput")
	if !exists {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "Invalid input data",
			"error":   "Validated input not found",
		})
		return
	}

	userInput := validatedInput.(*model.UserInput)

	// Update untuk handle error return dari service
	status, err := service.InsertUser(userInput)
	if !status {
		errorMsg := "Insert user failed"
		if err != nil {
			errorMsg = err.Error()
		}
		
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "Insert user failed",
			"error":   errorMsg,
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"code":    http.StatusCreated,
		"message": "User created successfully",
		"data": gin.H{
			"username": userInput.Username,
			"email":    userInput.Email,
		},
	})
}

func RegisterUser(c *gin.Context) {
	var registerInput model.RegisterInput

	// Bind JSON input
	if err := c.ShouldBindJSON(&registerInput); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "Invalid input data",
			"error":   err.Error(),
		})
		return
	}

	// Validasi input (pakai helper)
	if err := validateRegisterInput(&registerInput); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "Validation failed",
			"error":   err.Error(),
		})
		return
	}

	// Validasi password confirmation
	if registerInput.Password != registerInput.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "Registration failed",
			"error":   "Password and confirm password do not match",
		})
		return
	}

	// Hash password pakai bcrypt
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(registerInput.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "Failed to hash password",
			"error":   err.Error(),
		})
		return
	}
	registerInput.Password = string(hashedPassword)

	// Panggil service untuk register user
	status, err := service.InsertUserFromRegister(&registerInput)
	if !status {
		errorMsg := "Registration failed"
		if err != nil {
			errorMsg = err.Error()
		}

		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "User registration failed",
			"error":   errorMsg,
		})
		return
	}

	// Success response
	c.JSON(http.StatusCreated, gin.H{
		"code":    http.StatusCreated,
		"message": "User registration completed successfully",
		"data": gin.H{
			"userId":   registerInput.Username, 
			"username": registerInput.Username,
			"email":    registerInput.Email,
		},
	})
}


func UpdateUser(c *gin.Context) {
	usrId := c.Param("usrId")
	if usrId == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "User ID is required",
			"error":   "User ID parameter is not provided",
		})
		return
	}

	validatedInput, exists := c.Get("validatedInput")
	if !exists {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "Invalid input data",
			"error":   "Validated input not found",
		})
		return
	}

	userInput := validatedInput.(*model.UserInput)

	// Update untuk handle error return dari service (pass usrId as parameter)
	status, err := service.UpdateUser(usrId, userInput)
	if !status {
		errorMsg := "Update user failed"
		if err != nil {
			errorMsg = err.Error()
		}
		
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "Update user failed",
			"error":   errorMsg,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"message": "User updated successfully",
		"data": gin.H{
			"userId":   usrId,
			"username": userInput.Username,
		},
	})
}

func DeleteUser(c *gin.Context) {
	usrId := c.Param("usrId")
	if usrId == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "User ID is required",
			"error":   "User ID parameter is not provided",
		})
		return
	}

	// Update untuk handle error return dari service
	status, err := service.DeleteUser(usrId)
	if !status {
		errorMsg := "Delete user failed"
		if err != nil {
			errorMsg = err.Error()
		}
		
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "Delete user failed",
			"error":   errorMsg,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"message": "User deleted successfully",
		"data": gin.H{
			"deletedUserId": usrId,
		},
	})
}

func GetUserProfile(c *gin.Context) {
	
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code":    http.StatusUnauthorized,
			"message": "Unauthorized",
			"error":   "User ID not found in context",
		})
		return
	}

	role, roleExists := c.Get("role")
	if !roleExists {
		role = "user" // default role
	}

	// Get full user data
	user := service.GetOneUser(fmt.Sprintf("%v", userID))
	if user == nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code":    http.StatusNotFound,
			"message": "User profile not found",
			"error":   "User data not found in database",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"message": "User profile retrieved successfully",
		"data": gin.H{
			"userID":   userID,
			"role":     role,
			"profile":  user,
		},
	})
}

// Helper function untuk validasi input (opsional)
func validateRegisterInput(input *model.RegisterInput) error {
	if input.Username == "" {
		return fmt.Errorf("username is required")
	}
	if len(input.Username) < 3 {
		return fmt.Errorf("username must be at least 3 characters")
	}
	if input.Email == "" {
		return fmt.Errorf("email is required")
	}
	if input.Password == "" {
		return fmt.Errorf("password is required")
	}
	if len(input.Password) < 8 {
		return fmt.Errorf("password must be at least 8 characters")
	}
	if !input.AgreeTerms {
		return fmt.Errorf("must agree to terms and conditions")
	}
	return nil
}