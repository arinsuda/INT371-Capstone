package utils

import (
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

func GenerateBookingNumber() string {
	if node == nil {
		_ = InitSnowflakeNode(1)
	}
	return node.Generate().String()
}
