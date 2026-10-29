package repository

import (
	"context"

	"github.com/google/uuid"
	db "github.com/homepage408/go-rest-boilerplate/internal/repository/postgres"
	"github.com/jackc/pgx/v5/pgtype"
)

type AuthRepository struct {
	Queries *db.Queries
}

func NewAuth(q *db.Queries) AuthRepository {
	return AuthRepository{
		Queries: q,
	}
}

func (r *AuthRepository) CreateUser(ctx context.Context, params db.CreateUserParams) (db.CreateUserRow, error) {
	return r.Queries.CreateUser(ctx, params)
}

func (r *AuthRepository) CreateUserSession(ctx context.Context, arg db.CreateUserSessionParams) (db.CreateUserSessionRow, error) {
	return r.Queries.CreateUserSession(ctx, arg)
}
func (r *AuthRepository) DeleteExpiredUserSessions(ctx context.Context) (int64, error) {
	return r.Queries.DeleteExpiredUserSessions(ctx)
}

func (r *AuthRepository) DeleteRevokedUserSessionsBefore(ctx context.Context, revokedAt pgtype.Timestamptz) (int64, error) {
	return r.Queries.DeleteRevokedUserSessionsBefore(ctx, revokedAt)
}

func (r *AuthRepository) GetUserByEmail(ctx context.Context, emailLower string) (db.GetUserByEmailRow, error) {
	return r.Queries.GetUserByEmail(ctx, emailLower)
}
func (r *AuthRepository) GetUserByID(ctx context.Context, id uuid.UUID) (db.GetUserByIDRow, error) {
	return r.Queries.GetUserByID(ctx, id)
}

func (r *AuthRepository) GetUserSessionByRefreshTokenHash(ctx context.Context, refreshTokenHash string) (db.AuthSession, error) {
	return r.Queries.GetUserSessionByRefreshTokenHash(ctx, refreshTokenHash)
}

func (r *AuthRepository) ListUserSessions(ctx context.Context, userID uuid.UUID) ([]db.ListUserSessionsRow, error) {
	return r.Queries.ListUserSessions(ctx, userID)
}

func (r *AuthRepository) RevokeAllUserSessions(ctx context.Context, userID uuid.UUID) (int64, error) {
	return r.Queries.RevokeAllUserSessions(ctx, userID)
}

func (r *AuthRepository) RevokeUserSession(ctx context.Context, id uuid.UUID) (int64, error) {
	return r.Queries.RevokeUserSession(ctx, id)
}

func (r *AuthRepository) RotateRefreshToken(ctx context.Context, arg db.RotateRefreshTokenParams) (int64, error) {
	return r.Queries.RotateRefreshToken(ctx, arg)
}

func (r *AuthRepository) UpdateEmailVerifiedAt(ctx context.Context, id uuid.UUID) (int64, error) {
	return r.Queries.UpdateEmailVerifiedAt(ctx, id)
}

func (r *AuthRepository) UpdateUserPassword(ctx context.Context, arg db.UpdateUserPasswordParams) (int64, error) {
	return r.Queries.UpdateUserPassword(ctx, arg)
}

func (r *AuthRepository) UpdateUserStatus(ctx context.Context, arg db.UpdateUserStatusParams) (int64, error) {
	return r.Queries.UpdateUserStatus(ctx, arg)
}
