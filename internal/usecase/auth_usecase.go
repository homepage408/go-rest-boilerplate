package usecase

import (
	authRepo "github.com/homepage408/go-rest-boilerplate/internal/repository"
)

type AuthUsecase struct {
	AuthRepository authRepo.AuthRepository
}

func NewAuthUSecase(r authRepo.AuthRepository) AuthUsecase {
	return AuthUsecase{
		AuthRepository: r,
	}
}
