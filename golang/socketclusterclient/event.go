package socketcluster

import (
	"bytes"
	"encoding/gob"
)

type DictData map[string]interface{}
type StringData string

type Event struct {
	Event string       `json:"event,omitempty"`
	Data  *interface{} `json:"data,omitempty"`
	Cid   int          `json:"cid,omitempty"`
	Rid   int          `json:"rid,omitempty"`
}

func (event *Event) GetDataBytes() ([]byte, error) {
	var buf bytes.Buffer
	enc := gob.NewEncoder(&buf)
	err := enc.Encode(event.Data)
	if err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func makeEmptyEvent() *Event {
	return &Event{
		Event: "dummy",
		Data:  nil,
		Cid:   0,
		Rid:   0,
	}
}

func makeHandshakeData() DictData {
	//TODO: Persist authtoken, retrieve persisted token
	data := make(DictData)
	data["authToken"] = "randomjunk"
	return data
}

func makeLoginData(auth AuthDetails) DictData {
	data := make(DictData)
	data["profileName"] = auth.ProfileName
	data["auth_token"] = auth.AuthToken
	return data
}

func makeClearOldSessionsData(auth AuthDetails) StringData {
	return StringData(auth.ProfileName)
}
