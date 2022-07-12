package hellow

import (
	"context"
	"fmt"
	"math/rand"
)

// New returns the Hello World service.
func New() *Service {
	return &Service{}
}

// Service defines the Hello World service.
type Service struct {
}

// HelloWorld replies to the request with "Hello, World!".
func (s *Service) HelloWorld(ctx context.Context, _ string) (string, error) {
	return s.Hello(ctx, "World")
}

// Hello replies to the request with "Hello, %{name}!", where name is the
// argument passed in to the RPC request.
func (s *Service) Hello(ctx context.Context, name string) (string, error) {
	number := rand.Intn(1000)
	condition := number%2 == 0
	if condition {
		return fmt.Sprintf("Hello, %s! and your number %d is even", name, number), nil
	} else {
		return fmt.Sprintf("Hello, %s! and your number %d is odd", name, number), nil
	}

}
