package storage

import (
	"context"
	"net"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

func buildMinioClient(publicEndpoint, internalEndpoint, accessKey, secretKey, region string, useSSL bool) (*minio.Client, error) {

	tr, err := minio.DefaultTransport(useSSL)
	if err != nil {
		return nil, err
	}

	tr.DialContext = func(ctx context.Context, network, addr string) (net.Conn, error) {
		return net.Dial(network, internalEndpoint)
	}

	return minio.New(publicEndpoint, &minio.Options{
		Creds:        credentials.NewStaticV4(accessKey, secretKey, ""),
		Secure:       useSSL,
		Region:       region,
		Transport:    tr,
		BucketLookup: minio.BucketLookupPath,
	})
}
