package subdistrict

type SubDistrictResponse struct {
	ID         uint   `json:"id"`
	NameTH     string `json:"name_th"`
	PostalCode string `json:"postal_code"`
	DistrictID uint   `json:"district_id"`
	ProvinceID uint   `json:"province_id"`
}

func ToResponse(s *SubDistrict) SubDistrictResponse {
	return SubDistrictResponse{
		ID:         s.ID,
		NameTH:     s.NameTH,
		PostalCode: s.PostalCode,
		DistrictID: s.DistrictID,
		ProvinceID: s.District.ProvinceID,
	}
}

func ToResponseList(items []*SubDistrict) []SubDistrictResponse {
	out := make([]SubDistrictResponse, len(items))
	for i, item := range items {
		out[i] = ToResponse(item)
	}
	return out
}
