package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	dto "github.com/homepage408/go-rest-boilerplate/internal/delivery/http/dto"
	authUsecase "github.com/homepage408/go-rest-boilerplate/internal/usecase"
)

type AuthHandler struct {
	AuthUsecase authUsecase.AuthUsecase
}

type dataResponse struct{}

func NewAuthHandler(u authUsecase.AuthUsecase) AuthHandler {
	return AuthHandler{
		AuthUsecase: u,
	}
}

func (h *AuthHandler) Login(c *gin.Context) {

	data := dataResponse{}

	c.JSON(http.StatusOK, dto.SuccessResponse[dataResponse]{
		Success: true,
		Message: "Success",
		Data:    data,
	})
}
