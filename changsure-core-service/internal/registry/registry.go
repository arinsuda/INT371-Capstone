package registry

import (
	"changsure-core-service/src/modules/customers"
	"changsure-core-service/src/modules/provinces"
	"changsure-core-service/src/modules/reservation_statuses"
	"changsure-core-service/src/modules/reservations"
	"changsure-core-service/src/modules/service_categories"
	"changsure-core-service/src/modules/services"
	"changsure-core-service/src/modules/technicians"

	"gorm.io/gorm"
)

// Container holds all dependencies
type Container struct {
	DB *gorm.DB

	// Repositories
	CustomerRepo    customers.Repository
	// TechnicianRepo  technicians.Repository
	// ReservationRepo reservations.Repository

	// Services
	CustomerService    customers.Service
	// TechnicianService  technicians.Service
	// ReservationService reservations.Service

	// Handlers
	CustomerHandler    *customers.Handler
	// TechnicianHandler  *technicians.Handler
	// ReservationHandler *reservations.Handler
}

// NewContainer creates and initializes all dependencies
func NewContainer(db *gorm.DB) *Container {
	c := &Container{DB: db}

	// Initialize repositories
	c.CustomerRepo = customers.NewRepository(db)
	// c.TechnicianRepo = technicians.NewRepository(db)
	// c.ReservationRepo = reservations.NewRepository(db)

	// Initialize services
	c.CustomerService = customers.NewService(c.CustomerRepo)
	// c.TechnicianService = technicians.NewService(c.TechnicianRepo)
	// c.ReservationService = reservations.NewService(
	// 	c.ReservationRepo,
	// 	c.CustomerRepo,
	// 	c.TechnicianRepo,
	// )

	// Initialize handlers
	c.CustomerHandler = customers.NewHandler(c.CustomerService)
	// c.TechnicianHandler = technicians.NewHandler(c.TechnicianService)
	// c.ReservationHandler = reservations.NewHandler(c.ReservationService)

	return c
}

// AllModels returns all models for migration
func AllModels() []interface{} {
	var all []interface{}
	all = append(all, provinces.Models()...)
	all = append(all, reservation_statuses.Models()...)
	all = append(all, service_categories.Models()...)
	all = append(all, services.Models()...)
	all = append(all, technicians.Models()...)
	all = append(all, customers.Models()...)
	all = append(all, reservations.Models()...)
	return all
}
