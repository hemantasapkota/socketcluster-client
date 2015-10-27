package main

import (
	olapi "OpenLearningMobile/olapi"
	scluster "OpenLearningMobile/socketcluster"
	"fmt"
	"io/ioutil"
	"log"
)

func main() {
	serverConfig, _ := ioutil.ReadFile("../../olapi/server_config.json")
	server, err := olapi.NewServer(string(serverConfig), "Australia/Sydney")

	if err != nil {
		log.Println("Could not create server object")
		return
	}

	user := "laex.pearl"
	pwd := "asdasd"
	secure := true
	dbpath := ""

	// user := "super"
	// pwd := "superman"
	// secure := false

	sc, err := olapi.NewSocketClusterClient(server, dbpath, user, pwd, secure)
	if err != nil {
		fmt.Printf("%v", err)
		return
	}

	// OnAuthSuccess
	sc.Client.OnAuthSuccess = func() {
		// Subscribe: onlineList, chat
		for _, group := range sc.AuthObject.User.Groups {
			sc.Client.Subscribe([]string{"onlineList", "chat", group})
		}

		// Subscribe: available, chat, group, user, mobile/desktop
		user := sc.AuthObject.User.ProfileName
		for _, group := range sc.AuthObject.User.Groups {
			sc.Client.Subscribe([]string{"available", "chat", group, user, "mobile"})
		}

		// Get Initial Online List
		for _, group := range sc.AuthObject.User.Groups {
			sc.Client.SubscribeAny([]string{"getInitialOnlineList"}, []string{"chat", group})
		}
	}

	// OnData
	sc.Client.OnData = func(event *scluster.Event) {
		if event.Data != nil {
			// println("Data for id: ", event.Rid)
		}
	}

	for {
	}
}
