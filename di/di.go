package di

import (
	"context"

	"github.com/homepage408/go-rest-boilerplate/config"
	infrastructure "github.com/homepage408/go-rest-boilerplate/internal/infrastructure"
	"github.com/jackc/pgx/v5/pgxpool"
	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/redis/go-redis/v9"
)

// dependency injection

type Application struct {
	cfg   config.Config
	db    *pgxpool.Pool
	redis *redis.Client
	mq    *amqp.Connection
	// logger logger.Logger
	// routes *Routes // HTTP + GraphQL routes
}

func New(ctx context.Context, cfg config.Config) (*Application, func(), error) {
	// database
	db, err := infrastructure.InitDB(ctx, cfg.Database.DSN)
	if err != nil {
		return nil, nil, err
	}

	// Redis
	_, err = infrastructure.InitRedis(ctx, cfg.Redis.URL)
	if err != nil {
		return nil, nil, err
	}

	// message broker (Rabbit Mq)
	_, err = infrastructure.InitRabbitMQ(cfg.RabbitMq.URL)
	if err != nil {
		return nil, nil, err
	}

	app := &Application{
		cfg: cfg,
		db:  db,
		// redis: redis,
		// mq:    rabbitMq.Conn,
	}

	cleanup := func() {
		db.Close()
		// redis.Close()
		// rabbitMq.Conn.Close()
	}

	return app, cleanup, nil
}
