package infrastructure

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type JWT struct {
	SecretKey           string
	ExpiresAccessToken  time.Duration
	ExpiresRefreshToken time.Duration
}

func (j *JWT) GenerateAccessToken(userID, sessionID string) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID,
		"sid": sessionID,
		"typ": "access",
		"exp": jwt.NewNumericDate(time.Now().Add(j.ExpiresAccessToken)),
	}

	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString([]byte(j.SecretKey))
}

func (j *JWT) GenerateRefreshToken(userID, sessionID string) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID,
		"sid": sessionID,
		"typ": "refresh",
		"exp": jwt.NewNumericDate(time.Now().Add(j.ExpiresAccessToken)),
	}
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString([]byte(j.SecretKey))
}

func (j *JWT) ParseToken(tokenStr string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(j.SecretKey), nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, jwt.ErrTokenSignatureInvalid
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		return claims, nil
	}

	return nil, jwt.ErrTokenSignatureInvalid
}

func (j *JWT) HashRefreshToken(refreshToken string) string {
	hash := sha256.Sum256([]byte(refreshToken))
	return hex.EncodeToString(hash[:])
}

// TranslateError menerjemahkan error internal jwt/v5 ke pesan yang ramah pengguna
func (j *JWT) TranslateError(err error) (string, int) {
	if err == nil {
		return "", 200
	}

	if errors.Is(err, jwt.ErrTokenExpired) {
		return "token has expired", 401
	}

	if errors.Is(err, jwt.ErrTokenMalformed) {
		return "invalid token format", 400
	}

	if errors.Is(err, jwt.ErrTokenSignatureInvalid) {
		return "token signature is invalid", 401
	}

	if errors.Is(err, jwt.ErrTokenInvalidClaims) {
		return "token claims are invalid", 401
	}

	return "unauthorized: token is invalid", 401
}
