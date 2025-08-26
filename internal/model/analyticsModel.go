
package model

import (
	"time"
)


type MonthlyUserData struct {
	Month  string  `json:"month" gorm:"column:month"`
	Users  int     `json:"users" gorm:"column:users"`
	Growth float64 `json:"growth" gorm:"column:growth"`
}


type AnalyticsResponse struct {
	MonthlyRegistrations []MonthlyUserData `json:"monthly_registrations"`
	TotalUsers           int               `json:"total_users"`
	CurrentMonth         int               `json:"current_month"`
	GrowthRate           float64           `json:"growth_rate"`
}

type AnalyticsUser struct {
	ID        uint      `json:"id" gorm:"primaryKey;autoIncrement"`
	Email     string    `json:"email" gorm:"column:email;uniqueIndex;not null"`
	CreatedAt time.Time `json:"created_at" gorm:"column:created_at;autoCreateTime"`
	UpdatedAt time.Time `json:"updated_at" gorm:"column:updated_at;autoUpdateTime"`
}

