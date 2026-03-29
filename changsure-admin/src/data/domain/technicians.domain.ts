export interface TechnicianStats {
  total: number
  passed: number
  failed: number
  pending: number
}

export interface TechnicianResponse {
  page: number
  page_size: number
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
  account_status: string
  post_warning_status: string
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

export interface TechnicianDetail {
  id: number
  firstname: string
  lastname: string
  phone: string
  email: string
  avatar_url: string
  rating_count: number
  total_jobs: number
  is_available: boolean
  verification_status: "PASSED" | "PENDING" | "FAILED"
  terms_accepted: boolean
  privacy_accepted: boolean
  provinces: Province[]
  services: Service[]
  service_summary: ServiceSummary[]
  badges: any[]
  primary_address?: PrimaryAddress
  created_at: number
  updated_at: number
}

export interface PrimaryAddress {
  id: number
  label: string
  address_line: string
  sub_district_name: string
  district_name: string
  province_name: string
  postal_code: string
}

export interface TechnicianActivities {
  items: TechnicianActivity[]
  total: number
  page: number
  per_page: number
}

export interface TechnicianActivity {
  id: number
  technician_id: number
  title: string
  description: string
  service_id: number | null
  service_name: string | null
  category_id: number
  category_name: string
  province_id: number | null
  province_name: string | null
  images?: ActivityImages[] // ถ้าอนาคตเป็น object ค่อยปรับ
  is_published: boolean
  created_at: number // ⚠️ เป็น timestamp (unix)
}

export interface ActivityImages {
  id: number
  image_url: string
  order: number
}

export interface AdminInfo {
  id: number
  first_name: string
  last_name: string
  avatar_url: string
}

export type ReportSeverity = "WARNING" | "BLACKLIST"

export interface TechnicianPostReport {
  id: number
  post_id: number
  technician_id: number
  report_type: string
  reason: string
  severity: ReportSeverity
  delete_post: boolean
  admin: AdminInfo
  reported_at: number // unix timestamp
}

export interface TechnicianPostReportsResponse {
  items: TechnicianPostReport[]
  total: number
  page: number
  per_page: number
}

export interface TechnicianPostReportRequest {
  report_type: string
  reason?: string
  severity: ReportSeverity
  delete_post?: boolean
}

export interface TechnicianPostReportResponse {
  success: boolean
  message?: string
}


// types/technician-verification.ts

export interface TechnicianVerificationDetail {
  technician_id: number
  first_name: string
  last_name: string
  email: string
  phone: string
  avatar_url: string | null
  service_names: string[]
  province_names: string[]
  registered_at: number
  verification_status: "PASSED" | "PENDING" | "FAILED"
  national_id: string
  extracted_name: string | null
  id_card_image_url: string
  criminal_record: string | null
  latest_log: VerificationLog | null
}

export interface VerificationLog {
  id: number
  technician_id: number
  technician_name: string
  national_id: string
  status: "PASSED" | "PENDING" | "FAILED"
  note: string
  raw_ocr_text: string
  id_card_image_url: string
  created_at: string
}