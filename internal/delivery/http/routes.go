package http

import (
	"github.com/gin-gonic/gin"
	"github.com/homepage408/go-rest-boilerplate/di"
)

func NewRouter(app *di.Application) *gin.Engine {
	router := gin.Default()

	v1 := router.Group("/api/v1")
	{
		// Users routes
		auth := v1.Group("/auth")
		{
			// users.POST("/register", userHandler.Register)
			auth.POST("/login")
		}
	}
	return router
}
