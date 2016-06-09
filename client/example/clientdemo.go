package main

import (
	"fmt"
	socketcluster "github.com/hemantasapkota/socketcluster-client/golang/socketclusterclient"
)

func main() {

	authDetails := socketcluster.AuthDetails{
		Host:        "localhost:8000",
		ProfileName: "",
		AuthToken:   "",
		UserAgent:   "",
		SecureWS:    false,
	}

	dbPath := "./"

	sc, err := socketcluster.NewClient(authDetails, dbPath)
	if err != nil {
		fmt.Printf("%v", err)
		return
	}

	// OnAuthSuccess
	sc.OnAuthSuccess = func() {
		// Auth has been successful.
	}

	// OnData
	sc.OnData = func(event *socketcluster.Event) {
		if event.Data != nil {
			// println("Data for id: ", event.Rid)
		}
	}

	for {
	}
}
