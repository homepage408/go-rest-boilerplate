package infrastructure

import (
	"fmt"
	"log"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

type RabbitMqClient struct {
	Conn    *amqp.Connection
	Channel *amqp.Channel
	URL     string
}

func InitRabbitMQ(url string) (*RabbitMqClient, error) {
	client := &RabbitMqClient{URL: url}
	if err := client.connect(); err != nil {
		return nil, err
	}

	// reconnect
	go client.handleReconnect()
	return client, nil
}

func (r *RabbitMqClient) connect() error {
	var err error
	r.Conn, err = amqp.Dial(r.URL)
	if err != nil {
		return fmt.Errorf("failed to connect to RabbitMQ: %w", err)
	}

	r.Channel, err = r.Conn.Channel()
	if err != nil {
		r.Conn.Close()
		return fmt.Errorf("failed to open a channel: %w", err)
	}

	return nil
}

func (r *RabbitMqClient) handleReconnect() {
	for {
		closeErr := make(chan *amqp.Error)
		r.Conn.NotifyClose(closeErr)

		err := <-closeErr
		if err != nil {
			log.Printf("RabbitMQ connection closed: %v. Reconnecting...", err)

			for {
				time.Sleep(5 * time.Second)
				if err := r.connect(); err == nil {
					log.Println("Successfully reconnected to RabbitMQ")
					break // Keluar dari loop pencarian koneksi, kembali mendengarkan NotifyClose
				}
				log.Println("Retrying RabbitMQ connection...")
			}
		}
	}
}
