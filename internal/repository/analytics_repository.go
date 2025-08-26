package repository

import (
	"fmt"
	"time"

	"BackendFramework/internal/model"
	"BackendFramework/internal/database"

	"gorm.io/gorm"
)

type AnalyticsRepository struct {
	db *gorm.DB
}

func NewAnalyticsRepository() *AnalyticsRepository {
	return &AnalyticsRepository{
		db: database.DbCore,
	}
}


func (r *AnalyticsRepository) GetMonthlyUserRegistrations() ([]model.MonthlyUserData, error) {
	var monthlyData []model.MonthlyUserData

	query := `
		WITH monthly_counts AS (
			SELECT 
				DATE_FORMAT(created_at, '%b') as month,
				MONTH(created_at) as month_num,
				YEAR(created_at) as year,
				COUNT(*) as users
			FROM users 
			WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
			GROUP BY YEAR(created_at), MONTH(created_at)
			ORDER BY year DESC, month_num DESC
		),
		with_growth AS (
			SELECT 
				month,
				month_num,
				year,
				users,
				LAG(users) OVER (ORDER BY year, month_num) as prev_users
			FROM monthly_counts
		)
		SELECT 
			month,
			users,
			CASE 
				WHEN prev_users IS NULL OR prev_users = 0 THEN 0.0
				ELSE ROUND(((users - prev_users) * 100.0 / prev_users), 1)
			END as growth
		FROM with_growth
		ORDER BY year, month_num;
	`

	// pakai Raw GORM
	if err := r.db.Raw(query).Scan(&monthlyData).Error; err != nil {
		return nil, fmt.Errorf("failed to execute query: %v", err)
	}

	// Lengkapi bulan yang kosong
	monthlyData = r.fillMissingMonths(monthlyData)

	return monthlyData, nil
}

// GetTotalUsers returns total number of registered users
func (r *AnalyticsRepository) GetTotalUsers() (int, error) {
	var total int64
	if err := r.db.Model(&model.User{}).Count(&total).Error; err != nil {
		return 0, fmt.Errorf("failed to get total users: %v", err)
	}
	return int(total), nil
}


func (r *AnalyticsRepository) GetCurrentMonthUsers() (int, error) {
	var count int64
	startOfMonth := time.Now().UTC().Truncate(24 * time.Hour).AddDate(0, 0, -time.Now().Day()+1)

	if err := r.db.Model(&model.User{}).
		Where("created_at >= ?", startOfMonth).
		Count(&count).Error; err != nil {
		return 0, fmt.Errorf("failed to get current month users: %v", err)
	}
	return int(count), nil
}


func (r *AnalyticsRepository) fillMissingMonths(data []model.MonthlyUserData) []model.MonthlyUserData {
	months := []string{"Jan", "Feb", "Mar", "Apr", "May", "Jun",
		"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

	monthMap := make(map[string]model.MonthlyUserData)
	for _, d := range data {
		monthMap[d.Month] = d
	}

	var result []model.MonthlyUserData
	var prevUsers int = 0

	for _, month := range months {
		if existing, found := monthMap[month]; found {
			result = append(result, existing)
			prevUsers = existing.Users
		} else {
			
			var growth float64 = 0.0
			if prevUsers > 0 {
				growth = -100.0 
			}

			result = append(result, model.MonthlyUserData{
				Month:  month,
				Users:  0,
				Growth: growth,
			})
			prevUsers = 0
		}
	}

	return result
}
