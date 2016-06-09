package client

// TODO: Check if we need to parse event data into this struct
type AuthResponse struct {
	Id              string `json:"id"`
	IsAuthenticated bool   `json:"isAuthenticated"`
	PingTimeout     int64  `json:"pingTimeout"`
	AuthError       struct {
		Name    string `json:"name"`
		Message string `json:"message"`
	} `json:"authError"`
}

func isAuthenticated(event *Event) bool {
	data := *event.Data
	return data.(map[string]interface{})["isAuthenticated"].(bool)
}
