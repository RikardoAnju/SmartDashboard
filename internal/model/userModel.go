package model

import (
	"time"
	"gorm.io/gorm"
)


type UserList struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Group    string `json:"group"`
	IsAktif  string `json:"isAktif"`
	Password string `json:"password,omitempty"`
}




type UserInput struct {
	Username    string `json:"username" validate:"required,min=3"`
	FirstName   string `json:"firstName" validate:"required"`
	LastName    string `json:"lastName" validate:"required"`
	Email       string `json:"email" validate:"required,email"`
	Phone       string `json:"phone" validate:"required,min=10"`
	Password    string `json:"password" validate:"required,min=8"`
	Group       int    `json:"group" validate:"required"`
	IsAktif     string `json:"isAktif,omitempty"` 
}


type RegisterInput struct {
	Username            string `json:"username" validate:"required,min=3"`
	FirstName           string `json:"firstName" validate:"required"`
	LastName            string `json:"lastName" validate:"required"`
	Email               string `json:"email" validate:"required,email"`
	Phone               string `json:"phone" validate:"required,min=10"`
	Password            string `json:"password" validate:"required,min=8"`
	ConfirmPassword     string `json:"confirmPassword" validate:"required"`
	Group               int    `json:"group" validate:"required"`
	AgreeTerms          bool   `json:"agreeTerms" validate:"required"`
	SubscribeNewsletter bool   `json:"subscribeNewsletter"`
}

// Di file model/user.go
type User struct {
	ID                  uint           `json:"id" gorm:"primaryKey"`
	Username            string         `json:"username" gorm:"uniqueIndex;not null;size:100"`
	FirstName           string         `json:"firstName" gorm:"not null;size:100"`
	LastName            string         `json:"lastName" gorm:"not null;size:100"`
	Email               string         `json:"email" gorm:"uniqueIndex;not null;size:255"`
	Phone               string         `json:"phone" gorm:"not null;size:20"`
	Password            string         `json:"-" gorm:"not null"`
	Group               int            `json:"group" gorm:"not null;default:1"`
	IsAktif             string         `json:"isAktif" gorm:"size:20;default:'active'"`
	AgreeTerms          bool           `json:"agreeTerms" gorm:"default:false"`
	SubscribeNewsletter bool           `json:"subscribeNewsletter" gorm:"default:false"`
	CreatedAt           time.Time      `json:"createdAt" gorm:"autoCreateTime"`
	UpdatedAt           time.Time      `json:"updatedAt" gorm:"autoUpdateTime"`
	DeletedAt           gorm.DeletedAt `json:"-" gorm:"index"`
}

func (User) TableName() string {
	return "users" 
}


type FileInput struct {
	FileUpload      string `json:"fileupload" validate:"required"`    
	FileDescription string `json:"filedescription" validate:"required"`
}

// Response structures for API responses
type RegisterResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	User    *User  `json:"user,omitempty"`
}

type ErrorResponse struct {
	Success bool   `json:"success"`
	Error   string `json:"error"`
	Details string `json:"details,omitempty"`
}