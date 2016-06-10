package client

import (
	"code.google.com/p/go.net/websocket"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"sync"

	ldb "github.com/hemantasapkota/goma/gomadb/leveldb"
)

type AuthDetails struct {
	Host        string
	ProfileName string
	AuthToken   string
	UserAgent   string
	SecureWS    bool
}

type Client struct {
	ws       *websocket.Conn
	id       int
	mutex    *sync.Mutex
	quitChan chan int

	DB            *ldb.GomaDB
	OnAuthSuccess func()
	OnAuthFailure func(string)
	OnData        func(*Event)

	loginEvent Event
}

var Info *log.Logger

// Create a New SocketCluster Client
func NewClient(auth AuthDetails, dbpath string) (*Client, error) {
	Info = log.New(os.Stdout, "SOCKETCLUSTER: ", log.Ltime|log.Lshortfile)

	origin := "http://localhost"
	prefix := "ws"
	if auth.SecureWS {
		prefix = "wss"
	}

	url := fmt.Sprintf("%s://%s/socketcluster/", prefix, auth.Host)

	config, _ := websocket.NewConfig(url, origin)
	config.Header.Add("User-Agent", auth.UserAgent)

	Info.Println("Connecting: " + url)
	ws, err := websocket.DialConfig(config)
	if err != nil {
		Info.Println(err)
		return nil, err
	}

	c := &Client{
		ws:       ws,
		id:       0,
		mutex:    &sync.Mutex{},
		quitChan: make(chan int),
	}

	c.setupDB(dbpath)

	// Connection succeded. Send a handshake event.
	c.emit(c.NewEvent("#handshake", makeHandshakeData()))

	rEvent, err := c.recieve()

	if err != nil {
		Info.Println(err)
		return nil, errors.New("#handshake recieve error")
	}

	// Start listening to events
	go c.listen()

	if rEvent.Rid == 1 {
		if !isAuthenticated(rEvent) {
			c.emit(c.NewEvent("clearoldsessions", makeClearOldSessionsData(auth)))

			c.loginEvent = c.NewEvent("login", makeLoginData(auth))
			c.emit(c.loginEvent)
		}
	}

	return c, nil
}

// Create a new event
func (c *Client) NewEvent(name string, data interface{}) Event {
	return Event{Cid: c.newId(), Event: name, Data: &data}
}

// Emit a #subscribe event with a generic data
func (c *Client) Subscribe(data interface{}) string {
	// Subscribe requires json data to be sent to SC
	dataJson, _ := json.Marshal(data)
	dataStr := string(dataJson)
	event := c.NewEvent("#subscribe", dataStr)
	c.emit(event)

	// store the event in db
	id := string(event.Cid)
	c.AddEvent(id, dataStr)

	return id
}

func (c *Client) Unsubscribe(id string) error {
	data, err := c.GetEvent(id)
	if err != nil {
		return errors.New("Event not found. ID: " + id)
	}
	c.emit(c.NewEvent("#unsubscribe", data))
	return nil
}

func (c *Client) UnsubscribeMany(ids []string) {
	for _, id := range ids {
		c.Unsubscribe(id)
	}
}

// Emit a event with generic event & data
func (c *Client) SubscribeAny(event interface{}, data interface{}) int {
	eventJson, _ := json.Marshal(event)
	dataJson, _ := json.Marshal(data)

	eventAny := c.NewEvent(string(eventJson), string(dataJson))
	c.emit(eventAny)

	return eventAny.Cid
}

// listen
func (c *Client) listen() {
	recv, recvErr := c.receiver()
	for {
		select {
		case event := <-recv:
			c.dealWithEvent(event)

		case err := <-recvErr:
			Info.Println("Listen error : ", err)

		case <-c.quitChan:
			Info.Println("Stopping listening")
			return
		}
	}
}

func (c *Client) dealWithEvent(event *Event) {
	if event == nil {
		return
	}

	// Do we have an Event name ?
	name := event.Event
	if name == "#setAuthToken" {
	} else if name == "#publish" {
	}

	if event.Data != nil {
		c.OnData(event)
	}

	if event.Rid == c.loginEvent.Cid {
		if len(event.Error) > 0 {
			c.OnAuthFailure(event.Error)
		} else {
			c.OnAuthSuccess()
		}

		c.OnAuthSuccess()
	}
}

// Emit an event
func (c *Client) emit(event Event) {
	data, _ := json.Marshal(event)
	Info.Println(string(data))
	websocket.Message.Send(c.ws, data)
}

// PONG
func (c *Client) pong() {
	Info.Println("PONG")
	websocket.Message.Send(c.ws, "2")
}

func (c *Client) Close() {
	close(c.quitChan)
	c.ws.Close()
	ldb.CloseDB()
}

// Reciever channels
func (c *Client) receiver() (<-chan *Event, chan error) {
	ch, errCh := make(chan *Event), make(chan error)
	go func() {
		for {
			event, err := c.recieve()
			if err != nil {
				errCh <- err
				close(ch)
				return
			}
			ch <- event
		}
	}()
	return ch, errCh
}

func (c *Client) recieve() (*Event, error) {
	var message string
	websocket.Message.Receive(c.ws, &message)

	if message == "1" || message == "#1" {
		Info.Println("PING")
		c.pong()
		return makeEmptyEvent(), nil
	}
	var event Event
	err := json.Unmarshal([]byte(message), &event)
	if err != nil {
		return nil, err
	}

	if event.Event != "" {
		Info.Println("Recieved: " + event.Event)
	}

	return &event, nil
}

// Create a new ID
func (c *Client) newId() int {
	// Create ID in serial order
	c.mutex.Lock()
	c.id++
	c.mutex.Unlock()
	return c.id
}

func (c *Client) setupDB(dbpath string) error {
	var err error
	c.DB, err = ldb.InitDB(dbpath)
	if err != nil {
		return err
	}
	return nil
}

func (c *Client) AddEvent(id string, channelName string) error {
	return c.DB.Put(id, channelName)
}

func (c *Client) GetEvent(id string) (string, error) {
	return c.DB.Get(id)
}
