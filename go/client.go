// Package slipway is the Go client for the Slipway API.
//
//	client := slipway.NewClient("https://slipway.example.com", os.Getenv("SLIPWAY_TOKEN"))
//	me, err := client.Identity.WhoAmI(ctx, &slipwayv1.WhoAmIRequest{})
//
// Messages are in the slipway/v1 package and the service interfaces in slipway/v1/slipwayv1connect, which can also be
// used directly.
package slipway

import (
	"context"
	"net/http"

	connect "connectrpc.com/connect/v2"
	"connectrpc.com/connect/v2/connecthttp"
)

// Option changes how NewClient builds a Client.
type Option func(*options)

type options struct {
	httpClient   connecthttp.HTTPClient
	interceptors []connect.ClientInterceptor
}

// WithHTTPClient sets the HTTP client. The default has no overall timeout, because streams are long-lived: set
// deadlines per call with the context.
func WithHTTPClient(client connecthttp.HTTPClient) Option {
	return func(o *options) { o.httpClient = client }
}

// WithInterceptors adds interceptors, which run after the one that sets the token.
func WithInterceptors(interceptors ...connect.ClientInterceptor) Option {
	return func(o *options) { o.interceptors = append(o.interceptors, interceptors...) }
}

// NewClient returns a client for the server at baseURL that authenticates with token, a personal access token or a
// service-account token. An empty token sends no credentials. The service clients share one connection pool.
func NewClient(baseURL, token string, opts ...Option) *Client {
	o := options{httpClient: &http.Client{}}
	for _, opt := range opts {
		opt(&o)
	}
	interceptors := append([]connect.ClientInterceptor{bearer(token)}, o.interceptors...)
	return newClient(connect.NewClient(connecthttp.NewTransport(o.httpClient, baseURL), interceptors...))
}

// bearer sets the header per call rather than in a RoundTripper, so that net/http drops it on a cross-domain redirect.
func bearer(token string) connect.ClientInterceptor {
	return func(next connect.ClientFunc) connect.ClientFunc {
		return func(ctx context.Context, spec connect.Spec) (connect.ClientStream, error) {
			if info, ok := connect.CallInfoForClientContext(ctx); ok && token != "" {
				info.RequestHeader().Set("Authorization", "Bearer "+token)
			}
			return next(ctx, spec)
		}
	}
}
