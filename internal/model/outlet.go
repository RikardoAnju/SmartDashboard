package model

import (
    "time"
    "gorm.io/gorm"
)

type Outlet struct {
    ID        uint           `json:"id" gorm:"primarykey"`
    Name      string         `json:"name" gorm:"not null;size:255" validate:"required,min=3,max=255"`
    Address   string         `json:"address" gorm:"not null;type:text" validate:"required,min=10"`
    Phone     string         `json:"phone" gorm:"not null;size:20" validate:"required,min=10,max=20"`
    Manager   string         `json:"manager" gorm:"not null;size:255" validate:"required,min=3,max=255"`
    Status    string         `json:"status" gorm:"not null;default:'active'" validate:"required,oneof=active inactive"`
    OpenHours string         `json:"openHours" gorm:"not null;size:50" validate:"required"`
    CreatedAt time.Time      `json:"createdAt"`
    UpdatedAt time.Time      `json:"updatedAt"`
    DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`
}

type OutletRequest struct {
    Name      string `json:"name" validate:"required,min=3,max=255"`
    Address   string `json:"address" validate:"required,min=10"`
    Phone     string `json:"phone" validate:"required,min=10,max=20"`
    Manager   string `json:"manager" validate:"required,min=3,max=255"`
    Status    string `json:"status" validate:"required,oneof=active inactive"`
    OpenHours string `json:"openHours" validate:"required"`
}

type OutletResponse struct {
    ID        uint      `json:"id"`
    Name      string    `json:"name"`
    Address   string    `json:"address"`
    Phone     string    `json:"phone"`
    Manager   string    `json:"manager"`
    Status    string    `json:"status"`
    OpenHours string    `json:"openHours"`
    CreatedAt time.Time `json:"createdAt"`
    UpdatedAt time.Time `json:"updatedAt"`
}

func (o *Outlet) ToResponse() OutletResponse {
    return OutletResponse{
        ID:        o.ID,
        Name:      o.Name,
        Address:   o.Address,
        Phone:     o.Phone,
        Manager:   o.Manager,
        Status:    o.Status,
        OpenHours: o.OpenHours,
        CreatedAt: o.CreatedAt,
        UpdatedAt: o.UpdatedAt,
    }
}