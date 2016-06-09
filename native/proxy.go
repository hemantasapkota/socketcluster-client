package SocketClusterClient

import (
	socketcluster "socketcluster-client/client"

	"encoding/json"
	"errors"
)

var sc *socketcluster.Client
var err error

func NewSocketClusterClient(host string, profileName string, authToken string, userAgent string, secure bool, dbPath string) error {
	authDetails := socketcluster.AuthDetails{
		Host:        host,
		ProfileName: profileName,
		AuthToken:   authToken,
		UserAgent:   userAgent,
		SecureWS:    secure,
	}

	sc, err = socketcluster.NewClient(authDetails, dbPath)
	if err != nil {
		return err
	}

	sc.OnAuthSuccess = func() {
	}

	sc.OnData = func(event *socketcluster.Event) {
		data, err := json.Marshal(event)
		if err != nil {
			sc.DB.PutBytes("data", data)
		}
	}
	return nil
}

func Disconnect() {
	sc.Close()
	sc = nil
}

func GetData() ([]byte, error) {
	if sc.DB == nil {
		return nil, errors.New("Database is nil.")
	}
	return sc.DB.GetBytes("data")
}

func Subscribe(data []byte) (string, error) {
	var v interface{}
	err = json.Unmarshal(data, &v)
	if err != nil {
		return "", err
	}
	id := sc.Subscribe(v)
	return id, nil
}

func Unsubscribe(id string) error {
	return sc.Unsubscribe(id)
}
