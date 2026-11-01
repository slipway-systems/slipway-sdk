module github.com/slipway-systems/slipway-sdk/examples/go

go 1.26.0

require github.com/slipway-systems/slipway-sdk/go v0.0.0

require (
	connectrpc.com/connect/v2 v2.0.2 // indirect
	google.golang.org/protobuf v1.36.12 // indirect
)

replace github.com/slipway-systems/slipway-sdk/go => ../../go
