package main

import (
	"log"

	"BackendFramework/internal/config"
	"BackendFramework/internal/database"
	"BackendFramework/internal/middleware"
	"BackendFramework/internal/route"
)

func init() {
	config.InitEnvronment()
	config.InitDatabaseVars()
	config.InitEncryptionVars()
	config.InitBucketVars()
	config.InitEmailVars()

	middleware.InitLogger()
	middleware.InitValidator()

	database.OpenCore()
	database.OpenAuth()
}

func main() {
	router := route.SetupRouter()
	err := router.Run(":8080")
	if err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}