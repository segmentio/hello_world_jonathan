package hellow

import (
	"context"
	"net/http/httptest"
	"testing"

	"github.com/segmentio/rpc"
	"github.com/stretchr/testify/assert"
)

func TestHelloWorld(t *testing.T) {
	client, done := setup(t)
	defer done()

	var res string
	err := client.Call(context.Background(), "HelloWorld.HelloWorld", nil, &res)
	assert.NoError(t, err)
	assert.Equal(t, "Hello, World and the length of your name is 5", res)
}

func TestHello(t *testing.T) {
	client, done := setup(t)
	defer done()

	var res string
	err := client.Call(context.Background(), "HelloWorld.Hello", "Jonathan", &res)
	assert.NoError(t, err)
	assert.Equal(t, "Hello, Jonathan and the length of your name is 8", res)
}

func setup(t *testing.T) (*rpc.Client, func()) {
	srv := rpc.NewServer()
	srv.Register("HelloWorld", rpc.NewService(New()))

	server := httptest.NewServer(srv)
	client := rpc.NewClient(rpc.ClientConfig{
		UserAgent: "hello-world-test",
		URL:       server.URL + "/rpc",
	})

	return client, func() {
		server.Close()
	}
}
