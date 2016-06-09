package sc_client

import (
	socketcluster "socketcluster-client/client"
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

	return nil
}
