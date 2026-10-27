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
	-database "postgres://postgres:postgres@localhost:5432/syncra?sslmode=disable" \
	up

migrate-down:
	migrate -path db/migrations \
	-database "postgres://postgres:postgres@localhost:5432/syncra?sslmode=disable" \
	down