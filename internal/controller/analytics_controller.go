package controller

import (
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
    "BackendFramework/internal/database"
)

// Response struct
type MonthlyRegistration struct {
    Month  string  `json:"month"`
    Users  int     `json:"users"`
    Growth float64 `json:"growth"`
}

func GetUserRegistrations(c *gin.Context) {
    var results []MonthlyRegistration


    rows, err := database.DbCore.Raw(`
        SELECT DATE_FORMAT(created_at, '%b') AS month, COUNT(*) AS users
        FROM users
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
        GROUP BY DATE_FORMAT(created_at, '%Y-%m')
        ORDER BY MIN(created_at)
    `).Rows()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    defer rows.Close()

    prevUsers := 0
    for rows.Next() {
        var month string
        var users int
        rows.Scan(&month, &users)

        growth := 0.0
        if prevUsers > 0 {
            growth = (float64(users-prevUsers) / float64(prevUsers)) * 100
        }

        results = append(results, MonthlyRegistration{
            Month:  month,
            Users:  users,
            Growth: growth,
        })

        prevUsers = users
    }

    c.JSON(http.StatusOK, gin.H{
        "monthly_registrations": results,
        "generated_at":          time.Now(),
    })
}
