package registry

import (
	"changsure-core-service/src/modules/customers"
	"changsure-core-service/src/modules/provinces"
	"changsure-core-service/src/modules/reservation_statuses"
	"changsure-core-service/src/modules/reservations"
	"changsure-core-service/src/modules/service_categories"
	"changsure-core-service/src/modules/services"
	"changsure-core-service/src/modules/technicians"
)

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
