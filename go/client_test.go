package slipway_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"

	slipway "github.com/slipway-systems/slipway-sdk/go"
	slipwayv1 "github.com/slipway-systems/slipway-sdk/go/slipway/v1"
)

func TestNewClientSendsTheToken(t *testing.T) {
	tests := []struct {
		name, token, baseSuffix, wantAuth string
	}{
		{name: "token", token: "sk_test", wantAuth: "Bearer sk_test"},
		{name: "trailing slash on the base URL", token: "sk_test", baseSuffix: "/", wantAuth: "Bearer sk_test"},
		{name: "no token sends no header"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var gotAuth, gotPath string
			srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				gotAuth, gotPath = r.Header.Get("Authorization"), r.URL.Path
				w.Header().Set("Content-Type", "application/proto")
			}))
			defer srv.Close()

			client := slipway.NewClient(srv.URL+tt.baseSuffix, tt.token)
			if _, err := client.Identity.WhoAmI(context.Background(), &slipwayv1.WhoAmIRequest{}); err != nil {
				t.Fatalf("WhoAmI: %v", err)
			}
			if gotAuth != tt.wantAuth {
				t.Errorf("Authorization = %q, want %q", gotAuth, tt.wantAuth)
			}
			if want := "/slipway.v1.IdentityService/WhoAmI"; gotPath != want {
				t.Errorf("path = %q, want %q", gotPath, want)
			}
		})
	}
}

func TestNewClientSetsEveryService(t *testing.T) {
	client := reflect.ValueOf(slipway.NewClient("http://localhost", "")).Elem()
	for i := range client.NumField() {
		if client.Field(i).IsNil() {
			t.Errorf("%s is nil", client.Type().Field(i).Name)
		}
	}
}
