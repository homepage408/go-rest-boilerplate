
-- name: GetUserByEmail :one
SELECT
    id,
    email,
    password_hash,
    full_name,
    phone,
    status,
    email_verified_at,
    created_at,
    updated_at
FROM users
WHERE lower(email) = lower($1)
LIMIT 1;


-- name: GetUserByID :one
SELECT
    id,
    email,
    full_name,
    phone,
    status,
    email_verified_at,
    created_at,
    updated_at
FROM users
WHERE id = $1
  AND deleted_at IS NULL
LIMIT 1;


-- name: CreateUser :one
INSERT INTO users (
    email,
    password_hash,
    full_name,
    phone
)
VALUES (
    lower($1),
    $2,
    $3,
    $4
)
RETURNING
    id,
    email,
    full_name,
    phone,
    status,
    email_verified_at,
    created_at,
    updated_at;


-- name: UpdateUserPassword :execrows
UPDATE users
SET
    password_hash = $2,
    updated_at = now()
WHERE id = $1
  AND deleted_at IS NULL;


-- name: UpdateEmailVerifiedAt :execrows
UPDATE users
SET
    email_verified_at = COALESCE(email_verified_at, now()),
    updated_at = now()
WHERE id = $1
  AND deleted_at IS NULL;


-- name: UpdateUserStatus :execrows
UPDATE users
SET
    status = $2,
    updated_at = now()
WHERE id = $1
  AND deleted_at IS NULL;


-- name: CreateUserSession :one
INSERT INTO auth_sessions (
    user_id,
    refresh_token_hash,
    login_source,
    expires_at
)
VALUES (
    $1,
    $2,
    $3,
    $4
)
RETURNING
    id,
    user_id,
    login_source,
    expires_at,
    created_at;


-- name: GetUserSessionByRefreshTokenHash :one
SELECT
    id,
    user_id,
    refresh_token_hash,
    login_source,
    expires_at,
    revoked_at,
    created_at
FROM auth_sessions
WHERE refresh_token_hash = $1
LIMIT 1;


-- name: RotateRefreshToken :execrows
UPDATE auth_sessions
SET
    refresh_token_hash = $2,
    expires_at = $3
WHERE id = $1
  AND refresh_token_hash = $4
  AND revoked_at IS NULL
  AND expires_at > NOW();


-- name: RevokeUserSession :execrows
UPDATE auth_sessions
SET revoked_at = NOW()
WHERE id = $1
  AND revoked_at IS NULL;


-- name: RevokeAllUserSessions :execrows
UPDATE auth_sessions
SET revoked_at = NOW()
WHERE user_id = $1
  AND revoked_at IS NULL;


-- name: ListUserSessions :many
SELECT
    id,
    login_source,
    created_at,
    expires_at
FROM auth_sessions
WHERE user_id = $1
  AND revoked_at IS NULL
  AND expires_at > NOW()
ORDER BY created_at DESC;


-- name: DeleteExpiredUserSessions :execrows
DELETE FROM auth_sessions
WHERE expires_at <= NOW();


-- name: DeleteRevokedUserSessionsBefore :execrows
DELETE FROM auth_sessions
WHERE revoked_at IS NOT NULL
  AND revoked_at < $1;
