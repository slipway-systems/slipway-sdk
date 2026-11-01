// Command example calls WhoAmI on the server at SLIPWAY_URL with the token in SLIPWAY_TOKEN.
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
	client := slipway.NewClient(os.Getenv("SLIPWAY_URL"), os.Getenv("SLIPWAY_TOKEN"))
	me, err := client.Identity.WhoAmI(context.Background(), &slipwayv1.WhoAmIRequest{})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("user=%s method=%s\n", me.GetUser().GetEmail(), me.GetSessionMethod())
}
