package addressshared

import (
	"context"
	"fmt"

	"changsure-core-service/internal/modules/district"
	subdistrict "changsure-core-service/internal/modules/sub_district"
)

func NormalizeAndValidateLocation(
	ctx context.Context,
	provinceID, districtID, subDistrictID *uint,
	districtRepo district.Repository,
	subDistrictRepo subdistrict.Repository,
) (*uint, *uint, *uint, error) {

	fail := func(format string, a ...any) error {

		args := append([]any{ErrInvalidLocation}, a...)
		return fmt.Errorf("%w: "+format, args...)
	}

	if subDistrictID != nil {
		sd, err := subDistrictRepo.GetByID(ctx, *subDistrictID)
		if err != nil {
			return nil, nil, nil, err
		}
		if sd == nil || sd.ID == 0 {
			return nil, nil, nil, fail("sub_district_id=%d not found", *subDistrictID)
		}

		resolvedDistrictID := sd.DistrictID

		d, err := districtRepo.GetByID(ctx, resolvedDistrictID)
		if err != nil {
			return nil, nil, nil, err
		}
		if d == nil || d.ID == 0 {
			return nil, nil, nil, fail("district_id=%d (from sub_district_id=%d) not found", resolvedDistrictID, *subDistrictID)
		}

		resolvedProvinceID := d.ProvinceID

		if districtID != nil && *districtID != resolvedDistrictID {
			return nil, nil, nil, fail("sub_district_id=%d belongs to district_id=%d, but got district_id=%d", *subDistrictID, resolvedDistrictID, *districtID)
		}
		if provinceID != nil && *provinceID != resolvedProvinceID {
			return nil, nil, nil, fail("sub_district_id=%d belongs to province_id=%d, but got province_id=%d", *subDistrictID, resolvedProvinceID, *provinceID)
		}

		p := &resolvedProvinceID
		dd := &resolvedDistrictID
		return p, dd, subDistrictID, nil
	}

	if districtID != nil && provinceID != nil {
		d, err := districtRepo.GetByID(ctx, *districtID)
		if err != nil {
			return nil, nil, nil, err
		}
		if d == nil || d.ID == 0 {
			return nil, nil, nil, fail("district_id=%d not found", *districtID)
		}
		if d.ProvinceID != *provinceID {
			return nil, nil, nil, fail("district_id=%d belongs to province_id=%d, but got province_id=%d", *districtID, d.ProvinceID, *provinceID)
		}
	}

	return provinceID, districtID, subDistrictID, nil
}

func ValidateAddressFields(a *AddressFields) error {

	if a.Latitude != nil && (*a.Latitude < -90 || *a.Latitude > 90) {
		return fmt.Errorf("invalid latitude")
	}

	if a.Longitude != nil && (*a.Longitude < -180 || *a.Longitude > 180) {
		return fmt.Errorf("invalid longitude")
	}

	if a.PhoneNumber != nil && len(*a.PhoneNumber) != 10 {
		return fmt.Errorf("invalid phone number")
	}

	return nil
}
