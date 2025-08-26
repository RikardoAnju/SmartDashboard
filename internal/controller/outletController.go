
package controller

import (
    "net/http"
    "strconv"
    "BackendFramework/internal/middleware"
    "BackendFramework/internal/model"
    "BackendFramework/internal/service"
    "github.com/gin-gonic/gin"
)

type OutletController struct {
    outletService *service.OutletService
}

func NewOutletController() *OutletController {
    return &OutletController{
        outletService: service.NewOutletService(),
    }
}

func (ctrl *OutletController) GetOutlets(c *gin.Context) {
    search := c.Query("search")
    
    outlets, err := ctrl.outletService.GetAllOutlets(search)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error": "Failed to fetch outlets",
            "details": err.Error(),
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data": outlets,
        "message": "Outlets fetched successfully",
        "count": len(outlets),
    })
}

func (ctrl *OutletController) GetOutlet(c *gin.Context) {
    idStr := c.Param("id")
    id, err := strconv.ParseUint(idStr, 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": "Invalid outlet ID",
        })
        return
    }

    outlet, err := ctrl.outletService.GetOutletByID(uint(id))
    if err != nil {
        status := http.StatusInternalServerError
        if err.Error() == "outlet not found" {
            status = http.StatusNotFound
        }
        c.JSON(status, gin.H{
            "success": false,
            "error": err.Error(),
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data": outlet,
        "message": "Outlet fetched successfully",
    })
}


func (ctrl *OutletController) CreateOutlet(c *gin.Context) {
    var req model.OutletRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": "Invalid request data",
            "details": err.Error(),
        })
        return
    }

    if err := middleware.Validator.Struct(req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": "Validation failed",
            "details": err.Error(),
        })
        return
    }

    outlet, err := ctrl.outletService.CreateOutlet(req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error": "Failed to create outlet",
            "details": err.Error(),
        })
        return
    }

    c.JSON(http.StatusCreated, gin.H{
        "success": true,
        "data": outlet,
        "message": "Outlet created successfully",
    })
}


func (ctrl *OutletController) UpdateOutlet(c *gin.Context) {
    idStr := c.Param("id")
    id, err := strconv.ParseUint(idStr, 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": "Invalid outlet ID",
        })
        return
    }

    var req model.OutletRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": "Invalid request data",
            "details": err.Error(),
        })
        return
    }

    if err := middleware.Validator.Struct(req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": "Validation failed",
            "details": err.Error(),
        })
        return
    }

    outlet, err := ctrl.outletService.UpdateOutlet(uint(id), req)
    if err != nil {
        status := http.StatusInternalServerError
        if err.Error() == "outlet not found" {
            status = http.StatusNotFound
        }
        c.JSON(status, gin.H{
            "success": false,
            "error": err.Error(),
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data": outlet,
        "message": "Outlet updated successfully",
    })
}

// DeleteOutlet - DELETE /api/v1/outlets/:id
func (ctrl *OutletController) DeleteOutlet(c *gin.Context) {
    idStr := c.Param("id")
    id, err := strconv.ParseUint(idStr, 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "success": false,
            "error": "Invalid outlet ID",
        })
        return
    }

    err = ctrl.outletService.DeleteOutlet(uint(id))
    if err != nil {
        status := http.StatusInternalServerError
        if err.Error() == "outlet not found" {
            status = http.StatusNotFound
        }
        c.JSON(status, gin.H{
            "success": false,
            "error": err.Error(),
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "message": "Outlet deleted successfully",
    })
}

func (ctrl *OutletController) GetOutletStats(c *gin.Context) {
    stats, err := ctrl.outletService.GetOutletStats()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{
            "success": false,
            "error": "Failed to fetch outlet statistics",
            "details": err.Error(),
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "success": true,
        "data": stats,
        "message": "Outlet statistics fetched successfully",
    })
}