.PHONY: run build test sqlc gqlgen migrate-up migrate-down

include .env
export

run:
	go run cmd/api/main.go

build:
	go build -o bin/api cmd/api/main.go

test:
	go test ./...

sqlc:
	sqlc generate

gqlgen:
	go run github.com/99designs/gqlgen@v0.17.90 generate


migrate-up:
	migrate -path db/migrations \
		-database "$(DATABASE_URL)" \
		up

migrate-down:
	migrate -path db/migrations \
		-database "$(DATABASE_URL)" \
		down