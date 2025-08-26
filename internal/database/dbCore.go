package database

import (
	"log"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"BackendFramework/internal/config"
	"BackendFramework/internal/model" // Import model yang sudah ada
)

var DbCore *gorm.DB

func OpenCore() {
	var err error
	
	// Debug: Print konfigurasi database (hati-hati jangan print password di production)
	log.Printf("DB Config - Username: '%s', Hostname: '%s', DBName: '%s'", 
		config.DB_CORE_USERNAME, config.DB_CORE_HOSTNAME, config.DB_CORE_DBNAME)
	
	// Format DSN untuk MySQL
	dsn := config.DB_CORE_USERNAME + ":" + config.DB_CORE_PASSWORD + "@tcp(" + config.DB_CORE_HOSTNAME + ")/" + config.DB_CORE_DBNAME + "?charset=utf8mb4&parseTime=True&loc=Local"
	
	log.Printf("DSN: %s", dsn) // Debug DSN (hapus ini setelah berhasil)
	
	DbCore, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to DB Core with GORM: %v", err)
	}
	
	// Test koneksi
	sqlDB, err := DbCore.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying sql.DB from GORM: %v", err)
	}
	
	err = sqlDB.Ping()
	if err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	
	log.Println("Successfully connected to MySQL database with GORM")
	
	// Auto-migrate tables
	AutoMigrate()
}

// Optional: Fungsi untuk konfigurasi connection pool
func ConfigureConnectionPool() {
	sqlDB, err := DbCore.DB()
	if err != nil {
		log.Fatalf("Failed to get underlying sql.DB: %v", err)
	}
	
	// SetMaxIdleConns mengatur jumlah maksimum koneksi idle
	sqlDB.SetMaxIdleConns(10)
	
	// SetMaxOpenConns mengatur jumlah maksimum koneksi open
	sqlDB.SetMaxOpenConns(100)
	
	// SetConnMaxLifetime mengatur waktu maksimum koneksi dapat digunakan kembali
	// sqlDB.SetConnMaxLifetime(time.Hour)
}

// Optional: Fungsi untuk menutup koneksi database
func CloseCore() {
	sqlDB, err := DbCore.DB()
	if err != nil {
		log.Printf("Failed to get underlying sql.DB: %v", err)
		return
	}
	
	err = sqlDB.Close()
	if err != nil {
		log.Printf("Failed to close database connection: %v", err)
		return
	}
	
	log.Println("Database connection closed successfully")
}

// AutoMigrate - jalankan migrasi untuk membuat/update tabel menggunakan model yang sudah ada
func AutoMigrate() {
	err := DbCore.AutoMigrate(
		&model.User{}, // Menggunakan model User yang sudah didefinisikan
		// Tambahkan model lain di sini jika ada
	)
	if err != nil {
		log.Fatalf("Failed to auto-migrate database: %v", err)
	}
	log.Println("Database auto-migration completed successfully")
}