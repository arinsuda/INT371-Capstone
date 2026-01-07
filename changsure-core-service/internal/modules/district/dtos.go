package district

type DistrictResponse struct {
	ID         uint   `json:"id"`
	NameTH     string `json:"name_th"`
	ProvinceID uint   `json:"province_id"`
}

func ToResponse(d *District) DistrictResponse {
	return DistrictResponse{
		ID:         d.ID,
		NameTH:     d.NameTH,
		ProvinceID: d.ProvinceID,
	}
}

func ToResponseList(items []*District) []DistrictResponse {
	out := make([]DistrictResponse, len(items))
	for i, item := range items {
		out[i] = ToResponse(item)
	}
	return out
}
