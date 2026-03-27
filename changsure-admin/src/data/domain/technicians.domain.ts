export interface TechnicianStats {
  total: number
  passed: number
  failed: number
  pending: number
}

export interface TechnicianResponse {
  technicians: Technician[]
  total: number
  total_pages: number
  pending_count: number
  verified_count: number
}

export interface Technician {
  id: number
  avatar_url: string
  firstname: string
  lastname: string
  email: string
  phone?: string

  provinces: Province[]

  services: Service[]

  service_summary: ServiceSummary[]

  is_available: boolean
  is_verified: boolean
  verification_status: string
}

export interface Province {
  id: number
  name_th: string
  created_at: string
  updated_at: string
}

export interface Service {
  service_id: number
  service_name: string
  category_id: number
  category_name: string
  pricing_type: "FIXED" | "RANGE"
  price_fixed?: number
  price_min?: number
  price_max?: number
}

export interface ServiceSummary {
  service_category_id: number
  service_category_name: string
  services: {
    service_id: number
    service_name: string
  }[]
}