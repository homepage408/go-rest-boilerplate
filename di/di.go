package di

import (
	"context"

	"github.com/homepage408/go-rest-boilerplate/config"
	infrastructure "github.com/homepage408/go-rest-boilerplate/internal/infrastructure"
	"github.com/jackc/pgx/v5/pgxpool"
)

// dependency injection

type Application struct {
	cfg config.Config
	db  *pgxpool.Pool
	// logger logger.Logger
	// routes *Routes // HTTP + GraphQL routes
}

func New(ctx context.Context, cfg config.Config) (*Application, func(), error) {
	// database
	db, err := infrastructure.InitDB(ctx, cfg.Database.DSN)
	if err != nil {
		return nil, nil, err
	}

	app := &Application{
		cfg: cfg,
		db:  db,
	}

	cleanup := func() {
		db.Close()
	}

	return app, cleanup, nil
}
