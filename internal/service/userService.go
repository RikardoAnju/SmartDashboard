package service

import (
	"BackendFramework/internal/database"
	"BackendFramework/internal/middleware"
	"BackendFramework/internal/model"
	"fmt"
	"strconv"
)

func GetAllUsers() []model.UserList {
	var users []model.User
	var userList []model.UserList
	
	result := database.DbCore.Find(&users)
	if result.Error != nil {
		middleware.LogError(result.Error, "Query Error")
		return nil
	}
	
	// Convert User to UserList
	for _, user := range users {
		userList = append(userList, model.UserList{
			Username: user.Username,
			Email:    user.Email,
			Group:    fmt.Sprintf("%d", user.Group),
			IsAktif:  user.IsAktif,
		})
	}
	
	return userList
}

func GetOneUser(userId string) *model.UserList {
	var user model.User
	result := database.DbCore.Where("username = ?", userId).First(&user)
	if result.Error != nil {
		middleware.LogError(result.Error, "Data Not Found")
		return nil
	}
	
	return &model.UserList{
		Username: user.Username,
		Email:    user.Email,
		Group:    fmt.Sprintf("%d", user.Group),
		IsAktif:  user.IsAktif,
	}
}

func GetOneUserByUsername(userEmail string) *model.UserList {
	var user model.User
	result := database.DbCore.Where("email = ?", userEmail).First(&user)
	if result.Error != nil {
		middleware.LogError(result.Error, "Data Not Found")
		return nil
	}
	
	return &model.UserList{
		Username: user.Username,
		Email:    user.Email,
		Group:    fmt.Sprintf("%d", user.Group),
		IsAktif:  user.IsAktif,
	}
}

// NEW: Get users by group
func GetUsersByGroup(group string) []model.UserList {
	var users []model.User
	var userList []model.UserList
	
	// Convert string group to int
	groupInt, err := strconv.Atoi(group)
	if err != nil {
		middleware.LogError(err, "Invalid group parameter")
		return nil
	}
	
	result := database.DbCore.Where("\"group\" = ?", groupInt).Find(&users)
	if result.Error != nil {
		middleware.LogError(result.Error, "Query Error - Get Users By Group")
		return nil
	}
	
	// Convert User to UserList
	for _, user := range users {
		userList = append(userList, model.UserList{
			Username: user.Username,
			Email:    user.Email,
			Group:    fmt.Sprintf("%d", user.Group),
			IsAktif:  user.IsAktif,
		})
	}
	
	return userList
}

// Untuk UserInput
func InsertUser(userData *model.UserInput) (bool, error) {
	// Set default jika kosong
	if userData.IsAktif == "" {
		userData.IsAktif = "active"
	}
	
	// Konversi ke model User
	user := model.User{
		Username:  userData.Username,
		FirstName: userData.FirstName,
		LastName:  userData.LastName,
		Email:     userData.Email,
		Address:   userData.Address,
		Phone:     userData.Phone,
		Password:  userData.Password,
		Group:     userData.Group,
		IsAktif:   userData.IsAktif,
	}
	
	result := database.DbCore.Create(&user)
	if result.Error != nil {
		middleware.LogError(result.Error, "Insert Data Failed")
		return false, result.Error
	}
	
	fmt.Printf("User %s created successfully with ID: %d\n", user.Username, user.ID)
	return true, nil
}

// Untuk RegisterInput - INI YANG DIPAKAI UNTUK REGISTRATION
func InsertUserFromRegister(registerData *model.RegisterInput) (bool, error) {
	// Validasi
	if !registerData.AgreeTerms {
		return false, fmt.Errorf("user must agree to terms and conditions")
	}
	
	// Konversi RegisterInput ke User
	user := model.User{
		Username:            registerData.Username,
		FirstName:           registerData.FirstName,
		LastName:            registerData.LastName,
		Email:               registerData.Email,
		Address:             registerData.Address,
		Phone:               registerData.Phone,
		Password:            registerData.Password,
		Group:               registerData.Group,
		IsAktif:             "active", 
		AgreeTerms:          registerData.AgreeTerms,
		SubscribeNewsletter: registerData.SubscribeNewsletter,
	}
	
	// Create user dengan GORM
	result := database.DbCore.Create(&user)
	if result.Error != nil {
		middleware.LogError(result.Error, "Insert Registration Failed")
		return false, result.Error
	}
	
	fmt.Printf("User %s registered successfully with ID: %d\n", user.Username, user.ID)
	return true, nil
}

// UPDATED: UpdateUser now accepts usrId parameter
func UpdateUser(usrId string, userData *model.UserInput) (bool, error) {
	updates := model.User{
		FirstName: userData.FirstName,
		LastName:  userData.LastName,
		Email:     userData.Email,
		Address:   userData.Address,
		Phone:     userData.Phone,
		Group:     userData.Group,
		IsAktif:   userData.IsAktif,
		Password:  userData.Password,
	}
	
	result := database.DbCore.Model(&model.User{}).Where("username = ?", usrId).Updates(updates)
	if result.Error != nil {
		middleware.LogError(result.Error, "Update Data Failed")
		return false, result.Error
	}
	
	if result.RowsAffected == 0 {
		return false, fmt.Errorf("user with ID %s not found", usrId)
	}
	
	return true, nil
}

// NEW: Update user in group
func UpdateUserInGroup(usrId string, userData *model.UserInput) (bool, error) {
	// Check if user exists
	var existingUser model.User
	result := database.DbCore.Where("username = ?", usrId).First(&existingUser)
	if result.Error != nil {
		middleware.LogError(result.Error, "User not found for update")
		return false, fmt.Errorf("user with ID %s not found", usrId)
	}
	
	updates := model.User{
		FirstName: userData.FirstName,
		LastName:  userData.LastName,
		Email:     userData.Email,
		Address:   userData.Address,
		Phone:     userData.Phone,
		Group:     userData.Group,
		IsAktif:   userData.IsAktif,
		Password:  userData.Password,
	}
	
	result = database.DbCore.Model(&model.User{}).Where("username = ?", usrId).Updates(updates)
	if result.Error != nil {
		middleware.LogError(result.Error, "Update User in Group Failed")
		return false, result.Error
	}
	
	fmt.Printf("User %s updated successfully in group management\n", usrId)
	return true, nil
}

func DeleteUser(userId string) (bool, error) {
	result := database.DbCore.Where("username = ?", userId).Delete(&model.User{})
	if result.Error != nil {
		middleware.LogError(result.Error, "Delete Data Failed")
		return false, result.Error
	}
	
	if result.RowsAffected == 0 {
		return false, fmt.Errorf("user with ID %s not found", userId)
	}
	
	return true, nil
}

// NEW: Delete user from group
func DeleteUserFromGroup(usrId, group string) (bool, error) {
	// Check if user exists
	var existingUser model.User
	result := database.DbCore.Where("username = ?", usrId).First(&existingUser)
	if result.Error != nil {
		middleware.LogError(result.Error, "User not found for deletion")
		return false, fmt.Errorf("user with ID %s not found", usrId)
	}
	
	// If group is specified, validate user is in that group
	if group != "" {
		groupInt, err := strconv.Atoi(group)
		if err != nil {
			return false, fmt.Errorf("invalid group parameter: %s", group)
		}
		
		if existingUser.Group != groupInt {
			return false, fmt.Errorf("user %s is not in group %s", usrId, group)
		}
	}
	
	// Delete user
	result = database.DbCore.Where("username = ?", usrId).Delete(&model.User{})
	if result.Error != nil {
		middleware.LogError(result.Error, "Delete User from Group Failed")
		return false, result.Error
	}
	
	fmt.Printf("User %s deleted successfully from group %s\n", usrId, group)
	return true, nil
}