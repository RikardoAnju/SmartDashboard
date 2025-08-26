package v1

import (
    "github.com/gin-gonic/gin"
    "BackendFramework/internal/controller"
    "BackendFramework/internal/middleware"
    "BackendFramework/internal/model"
)

func InitRoutes(r *gin.RouterGroup) {
    // ---------------- AUTH ----------------
    auth := r.Group("/auth")
    {
        auth.POST("/login", controller.Login)
        auth.POST("/register", controller.RegisterUser)
        auth.GET("/logout/:usrId", controller.Logout)
        auth.POST("/refresh-access", middleware.LogUserActivity(), controller.RefreshAccessToken)
    }

    // ---------------- ANALYTICS ----------------
analytics := r.Group("/analytics")
{
    analytics.Use(middleware.JWTAuthMiddleware(), middleware.LogUserActivity())

    analytics.GET("/user-registrations", controller.GetUserRegistrations)
}


// ---------------- OUTLET MANAGEMENT ----------------
outlet := r.Group("/outlets")
{
    
    outlet.Use(middleware.JWTAuthMiddleware(), middleware.LogUserActivity())
    
    outletInput := &model.Outlet{}
    outletCtrl := controller.NewOutletController()
    
   
    outlet.GET("/", outletCtrl.GetOutlets)
    
    
    outlet.GET("/stats", outletCtrl.GetOutletStats)
    
  
    outlet.GET("/:id", outletCtrl.GetOutlet)
    
    
    outlet.POST("/", middleware.InputValidator(outletInput), outletCtrl.CreateOutlet)
    

    outlet.PUT("/:id", middleware.InputValidator(outletInput), outletCtrl.UpdateOutlet)
    outlet.PATCH("/:id", middleware.InputValidator(outletInput), outletCtrl.UpdateOutlet)
    
  
    outlet.DELETE("/:id", outletCtrl.DeleteOutlet)
}


    // ---------------- USER MANAGEMENT ----------------
    user := r.Group("/users")
    {
        
        user.Use(middleware.JWTAuthMiddleware(), middleware.LogUserActivity())
        
        userInput := &model.UserInput{}
        
        // READ - Get all users 
        user.GET("/", controller.GetUser)
        
        // READ - Get specific user 
        user.GET("/:usrId", controller.GetUser)
        
        // PROFILE - Get current user profile 
        user.GET("/profile", controller.GetUserProfile)
        
        // CREATE - Insert new user 
        user.POST("/", middleware.InputValidator(userInput), controller.InsertUser)
        
        // UPDATE - Update user 
        user.PUT("/:usrId", middleware.InputValidator(userInput), controller.UpdateUser)
        user.PATCH("/:usrId", middleware.InputValidator(userInput), controller.UpdateUser)
        
        // DELETE - Delete user 
        user.DELETE("/:usrId", controller.DeleteUser)
    }

    // ---------------- MISC ----------------
    misc := r.Group("/misc")
    {
        misc.Use(middleware.JWTAuthMiddleware(), middleware.LogUserActivity())

        // File upload
        fileInput := &model.FileInput{}
        misc.POST("/upload-data-s3-local", middleware.InputValidator(fileInput), controller.UploadFile)

        // Utility endpoints
        misc.GET("/generate-pdf", controller.TryGeneratePdf)
        misc.GET("/send-mail", controller.SendMail)
        misc.GET("/generate-excel", controller.GenerateExcel)
        misc.POST("/read-excel", controller.ReadExcel)
        misc.GET("/test-ping", controller.PingMongo)
    }
}