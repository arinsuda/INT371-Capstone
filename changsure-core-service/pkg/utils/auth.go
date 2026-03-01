package utils

import (
	"context"
)

type userIDContextKey struct{}

func InjectUserIDIntoContext(ctx context.Context, userID uint) context.Context {
	return context.WithValue(ctx, userIDContextKey{}, userID)
}

func GetUserIDFromContext(ctx context.Context) uint {
	id, _ := ctx.Value(userIDContextKey{}).(uint)
	return id
}
