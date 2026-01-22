package utils

import (
	"strings"
	"sync"

	"github.com/bwmarrin/snowflake"
)

var (
	node *snowflake.Node
	once sync.Once
)

func InitSnowflakeNode(nodeID int64) error {
	var err error
	once.Do(func() {
		node, err = snowflake.NewNode(nodeID)
	})
	return err
}

func GenerateSnowflakeID() string {
	if node == nil {
		_ = InitSnowflakeNode(1)
	}
	return node.Generate().String()
}

func GenerateBookingNumber10() string {
	if node == nil {
		_ = InitSnowflakeNode(1)
	}

	code := strings.ToUpper(node.Generate().Base36())

	if len(code) < 10 {
		code = strings.Repeat("0", 10-len(code)) + code
	}

	if len(code) > 10 {
		code = code[len(code)-10:]
	}

	return code
}
