package config

import (
	"errors"
	"os"
	"strconv"
	"time"

	duration "github.com/homepage408/go-rest-boilerplate/pkg/duration"
)

type ServerConfig struct {
	Host    string `mapstructure:"host"`
	Port    int    `mapstructure:"port"`
	AppName string
}

type PostgresConfig struct {
	DSN          string `mapstructure:"dsn"`
	MaxOpenConns int
	MaxIdleConns int
}

type RedisConfig struct {
	Addr     string `mapstructure:"addr"`
	Password string `mapstructure:"password"`
	DB       int    `mapstructure:"db"`
}

type RabbitMQConfig struct {
	URL string `mapstructure:"url"`
}

type TokenConfig struct {
	JWTSecret        string
	JWTExpiry        time.Duration
	JWTRefreshExpiry time.Duration
}

type Config struct {
	LogLevel          string
	Server            ServerConfig
	Database          PostgresConfig
	RabbitMq          RabbitMQConfig
	Redis             RedisConfig
	Token             TokenConfig
	RateLimit         int
	RateLimitInterval time.Duration
}

func Load() (*Config, error) {
	cfg := &Config{}

	cfg.LogLevel = os.Getenv("LOG_LEVEL")
	if cfg.LogLevel == "" {
		cfg.LogLevel = "info"
	}

	// database
	cfg.Database.DSN = os.Getenv("DATABASE_DSN")

	// apps
	cfg.Server.AppName = os.Getenv("APPS_NAME")
	port, err := strconv.Atoi(os.Getenv("PORT"))
	if err != nil {
		return cfg, errors.New("failed to parse 'PORT': invalid integer format")
	}
	cfg.Server.Port = port

	cfg.Database.MaxOpenConns = 20
	cfg.Database.MaxIdleConns = 10

	// token
	cfg.Token.JWTSecret = os.Getenv("JWT_SECRET")
	jwtExpiryStr := os.Getenv("JWT_EXPIRY")
	if jwtExpiryStr == "" {
		jwtExpiryStr = "1h" // Default to 1 hour if not set
	}

	jwtExpiry, err := time.ParseDuration(jwtExpiryStr)
	if err != nil {
		return cfg, errors.New("failed to parse 'JWT_EXPIRY': invalid time duration format")
	}
	cfg.Token.JWTExpiry = jwtExpiry

	jwtRefreshExpiryStr := os.Getenv("JWT_REFRESH_EXPIRY")
	if jwtRefreshExpiryStr == "" {
		jwtRefreshExpiryStr = "30d" // Default to 30 days if not set
	}
	jwtRefreshExpiry, err := duration.ParseDayDuration(jwtRefreshExpiryStr)
	if err != nil {
		return cfg, errors.New("failed to parse 'JWT_REFRESH_EXPIRY': invalid day duration format")
	}
	cfg.Token.JWTRefreshExpiry = jwtRefreshExpiry

	return cfg, nil
}
