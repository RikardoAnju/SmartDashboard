# BackendFramework
UIB Backend Framework (Golang Based API)

# Untuk Dependencies Check file requirement.txt
Untuk Bisa Generate PDF pastikan install ini terlebih dahulu https://wkhtmltopdf.org/downloads.html

# Folder Structure
``` 
/
├── cmd
│   └── main.go
├── internal
│   ├── config
│   │   ├── database.go
│   │   └── bucket.go
│   ├── controller
│   │   └── userController.go
│   ├── database
│   │   └── dbAkademik.go
│   ├── model
│   │   └── userModel.go
│   ├── middleware
│   │   └── reqAuth.go
│   ├── route
│   │   ├── v1
│   │   │   └── init.go
│   │   ├── v2
│   │   │   └── init.go
│   │   └── router.go
│   ├── service
│   │   └── userService.go
│   └── thirdparty
│       └── bucket.go
├── log
│   └── error.log
├── web
│   ├── html
│   ├── css
│   └── assets
└── temp
```
