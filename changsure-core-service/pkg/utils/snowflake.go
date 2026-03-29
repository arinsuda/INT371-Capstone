package utils

import (
	"fmt"
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

func GenerateBookingNumber10Digits() string {
	if node == nil {
		_ = InitSnowflakeNode(1)
	}

	id := int64(node.Generate())

	const mod int64 = 10_000_000_000
	n := id % mod
	if n < 0 {
		n = -n
	}

	return fmt.Sprintf("%010d", n)
}
