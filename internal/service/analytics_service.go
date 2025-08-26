
package service

import (
	"BackendFramework/internal/model"
	"BackendFramework/internal/repository"
)

type AnalyticsService struct {
	repo *repository.AnalyticsRepository
}

func NewAnalyticsService() *AnalyticsService {
	return &AnalyticsService{
		repo: repository.NewAnalyticsRepository(),
	}
}


func (s *AnalyticsService) GetUserRegistrationAnalytics() (*model.AnalyticsResponse, error) {
	// Get monthly registration data
	monthlyData, err := s.repo.GetMonthlyUserRegistrations()
	if err != nil {
		return nil, err
	}

	
	totalUsers, err := s.repo.GetTotalUsers()
	if err != nil {
		return nil, err
	}

	
	currentMonth, err := s.repo.GetCurrentMonthUsers()
	if err != nil {
		return nil, err
	}

	
	var growthRate float64 = 0.0
	if len(monthlyData) >= 2 {
		lastMonth := monthlyData[len(monthlyData)-1]
		growthRate = lastMonth.Growth
	}

	response := &model.AnalyticsResponse{
		MonthlyRegistrations: monthlyData,
		TotalUsers:          totalUsers,
		CurrentMonth:        currentMonth,
		GrowthRate:          growthRate,
	}

	return response, nil
}