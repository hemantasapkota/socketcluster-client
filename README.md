### SocketCluster Client ( IOS, Android & Golang ) ###
Socket Cluster Client for IOS, Android & Golang

### Dependencies ###

* Golang 1.5
* NodeJS

### Testing Locally ###

#### Update latest version of socketcluster server: ####
```
git subtree pull --prefix server https://github.com/SocketCluster/socketcluster master --squash
```

#### Run server locally ####
```
cd server && npm install
cd sample && npm install
node server.js
```

### Testing Go Client ###
```
cd golang/socketclusterclient/example
go run clientdemo.go
```

You should see the following output:
```
SOCKETCLUSTER: 14:04:15 client.go:65: Connecting: ws://localhost:8000/socketcluster/
SOCKETCLUSTER: 14:04:15 client.go:193: {"event":"#handshake","data":{"authToken":"randomjunk"},"cid":1}
SOCKETCLUSTER: 14:04:15 client.go:193: {"event":"clearoldsessions","data":"","cid":2}
SOCKETCLUSTER: 14:04:15 client.go:193: {"event":"login","data":{"auth_token":"","profileName":""},"cid":3}
SOCKETCLUSTER: 14:03:43 client.go:255: Recieved: rand
SOCKETCLUSTER: 14:03:47 client.go:255: Recieved: rand
SOCKETCLUSTER: 14:03:48 client.go:255: Recieved: rand
SOCKETCLUSTER: 14:03:49 client.go:244: PING
SOCKETCLUSTER: 14:03:49 client.go:199: PONG
SOCKETCLUSTER: 14:03:49 client.go:255: Recieved: rand
SOCKETCLUSTER: 14:03:53 client.go:255: Recieved: rand
SOCKETCLUSTER: 14:03:54 client.go:255: Recieved: rand
```
