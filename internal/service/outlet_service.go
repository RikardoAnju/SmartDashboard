package service

import (
	"BackendFramework/internal/database"
	"BackendFramework/internal/model"
	"errors"
	"strings"

	"gorm.io/gorm"
)

type OutletService struct{}

func NewOutletService() *OutletService {
    return &OutletService{}
}

func (s *OutletService) GetAllOutlets(search string) ([]model.OutletResponse, error) {
    var outlets []model.Outlet
    query := database.DbCore

    if search != "" {
        searchTerm := "%" + strings.ToLower(search) + "%"
        query = query.Where(
            "LOWER(name) LIKE ? OR LOWER(address) LIKE ? OR LOWER(manager) LIKE ?",
            searchTerm, searchTerm, searchTerm,
        )
    }

    if err := query.Find(&outlets).Error; err != nil {
        return nil, err
    }

    var responses []model.OutletResponse
    for _, outlet := range outlets {
        responses = append(responses, outlet.ToResponse())
    }

    return responses, nil
}

func (s *OutletService) GetOutletByID(id uint) (*model.OutletResponse, error) {
    var outlet model.Outlet
    if err := database.DbCore.First(&outlet, id).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, errors.New("outlet not found")
        }
        return nil, err
    }

    response := outlet.ToResponse()
    return &response, nil
}

func (s *OutletService) CreateOutlet(req model.OutletRequest) (*model.OutletResponse, error) {
    outlet := model.Outlet{
        Name:      req.Name,
        Address:   req.Address,
        Phone:     req.Phone,
        Manager:   req.Manager,
        Status:    req.Status,
        OpenHours: req.OpenHours,
    }

    if err := database.DbCore.Create(&outlet).Error; err != nil {
        return nil, err
    }

    response := outlet.ToResponse()
    return &response, nil
}

func (s *OutletService) UpdateOutlet(id uint, req model.OutletRequest) (*model.OutletResponse, error) {
    var outlet model.Outlet
    if err := database.DbCore.First(&outlet, id).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, errors.New("outlet not found")
        }
        return nil, err
    }

    outlet.Name = req.Name
    outlet.Address = req.Address
    outlet.Phone = req.Phone
    outlet.Manager = req.Manager
    outlet.Status = req.Status
    outlet.OpenHours = req.OpenHours

    if err := database.DbCore.Save(&outlet).Error; err != nil {
        return nil, err
    }

    response := outlet.ToResponse()
    return &response, nil
}

func (s *OutletService) DeleteOutlet(id uint) error {
    var outlet model.Outlet
    if err := database.DbCore.First(&outlet, id).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return errors.New("outlet not found")
        }
        return err
    }

    return database.DbCore.Delete(&outlet).Error
}

func (s *OutletService) GetOutletStats() (map[string]interface{}, error) {
    var totalOutlets int64
    var activeOutlets int64
    var inactiveOutlets int64

    
    if err := database.DbCore.Model(&model.Outlet{}).Count(&totalOutlets).Error; err != nil {
        return nil, err
    }

    
    if err := database.DbCore.Model(&model.Outlet{}).Where("status = ?", "active").Count(&activeOutlets).Error; err != nil {
        return nil, err
    }

    
    if err := database.DbCore.Model(&model.Outlet{}).Where("status = ?", "inactive").Count(&inactiveOutlets).Error; err != nil {
        return nil, err
    }

    stats := map[string]interface{}{
        "total":    totalOutlets,
        "active":   activeOutlets,
        "inactive": inactiveOutlets,
    }

    return stats, nil
}