# Slipway Go SDK

```bash
go get github.com/slipway-systems/slipway-sdk/go
```

```go
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	slipway "github.com/slipway-systems/slipway-sdk/go"
	slipwayv1 "github.com/slipway-systems/slipway-sdk/go/slipway/v1"
)

func main() {
	client := slipway.NewClient("https://slipway.example.com", os.Getenv("SLIPWAY_TOKEN"))
	me, err := client.Identity.WhoAmI(context.Background(), &slipwayv1.WhoAmIRequest{})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(me.GetUser().GetEmail())
}
```

`Client` has a field per API service (`Identity`, `Run`, `Deploy` and so on). Errors are `*connect.Error` from
`connectrpc.com/connect/v2`; use `connect.CodeOf(err)` to tell them apart.

Generated code is in `slipway/v1` (messages) and `slipway/v1/slipwayv1connect` (service clients), and can be used
without the helper. Requires Go 1.26 or later.

Licence: Apache-2.0.
