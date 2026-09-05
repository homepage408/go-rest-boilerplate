package di

import (
	"github.com/99designs/gqlgen/graphql/handler/apollofederatedtracingv1/logger"
	"github.com/jmoiron/sqlx"
)

// dependency injection

type Application struct {
	db     *sqlx.DB
	logger logger.Logger
	routes *Routes // HTTP + GraphQL routes
}
