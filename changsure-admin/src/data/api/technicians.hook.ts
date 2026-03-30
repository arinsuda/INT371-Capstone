import { UseMutationOptions } from "@tanstack/react-query"
import {
  QueryKeyT,
  useDelete,
  usePatch,
  useFetch,
  usePost,
  usePut
} from "./common/react_query"
import axios from "axios"
import {
  TechnicianResponse,
  TechnicianStats,
  TechnicianDetail,
  TechnicianActivities,
  TechnicianPostReportsResponse,
  TechnicianActivity,
  TechnicianPostReportRequest,
  TechnicianPostReportResponse,
  TechnicianVerificationDetail
} from "@/data/domain/technicians.domain"
const URL_API =
  process.env.NEXT_PUBLIC_URL_API ||
  "https://bscit.sit.kmutt.ac.th/capstone25/cp25ssa1/api"

export function useGetTechnicianStats() {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  return useFetch<TechnicianStats>(
    `${URL_API}/verification/stats`,
    ["technician-stats"], // ✅ query key
    undefined, // ✅ params (ไม่มี)
    undefined, // initialData
    {
      Authorization: `Bearer ${token}`
    }
  )
}

type TechnicianFilter = {
  verification_status?: string
  post_warning_status?: string
}

type PaginationParams = {
  page?: number
  pageSize?: number
}

export function useGetTechnicianResponse(
  pagination?: PaginationParams,
  filters?: TechnicianFilter
) {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  const queryParams = {
    ...(pagination?.page && { page: pagination.page }),
    ...(pagination?.pageSize && { page_size: pagination.pageSize }),

    ...(filters?.verification_status && {
      verification_status: filters.verification_status
    }),
    ...(filters?.post_warning_status && {
      post_warning_status: filters.post_warning_status
    })
  }

  return useFetch<TechnicianResponse>(
    `${URL_API}/technicians`,
    [
      "technicians",
      String(pagination?.page ?? 1),
      String(pagination?.pageSize ?? 10),
      filters?.verification_status ?? "all",
      filters?.post_warning_status ?? "all"
    ],
    queryParams,
    undefined,
    {
      Authorization: `Bearer ${token}`
    }
  )
}

export function useGetTechnicianById(id: number) {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  return useFetch<TechnicianDetail>(
    `${URL_API}/technicians/${id}`, // ✅ endpoint ใหม่
    [`technician-${id}`], // ✅ queryKey
    undefined,
    undefined,
    {
      Authorization: `Bearer ${token}`
    }
  )
}

export function useGetTechnicianPosts(
  technicianId: number,
  page: number = 1,
  perPage: number = 20
) {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  return useFetch<TechnicianActivities>(
    `${URL_API}/technicians/${technicianId}/posts?page=${page}&per_page=${perPage}`,
    ["technician-posts", String(technicianId), String(page), String(perPage)],
    undefined,
    undefined,
    {
      Authorization: `Bearer ${token}`
    }
  )
}

export function useGetTechnicianPostReports(technicianId: number) {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  const adminID =
    typeof window !== "undefined" ? localStorage.getItem("adminID") : null

  return useFetch<TechnicianPostReportsResponse>(
    `${URL_API}/admins/technicians/${technicianId}/posts/reports`,
    ["technician-post-reports", String(adminID), String(technicianId)],
    undefined,
    undefined,
    {
      Authorization: `Bearer ${token}`
    }
  )
}

export function useGetTechnicianPostById(technicianId: number, postId: number) {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  return useFetch<TechnicianActivity>(
    `${URL_API}/technicians/${technicianId}/posts/${postId}`,
    ["technician-post", String(technicianId), String(postId)],
    undefined,
    undefined,
    {
      Authorization: `Bearer ${token}`
    }
  )
}

export function useGetTechnicianReportTypes() {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  return useFetch<string[]>(
    `${URL_API}/report-types`,
    ["technician-report-types"],
    undefined,
    undefined,
    {
      Authorization: `Bearer ${token}`
    }
  )
}

export function useReportTechnicianPost(technicianId: number, postId: number) {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  return usePost<TechnicianPostReportResponse, TechnicianPostReportRequest>(
    `${URL_API}/admins/technicians/${technicianId}/posts/${postId}/report`,
    {
      headers: {
        Authorization: `Bearer ${token}`
      }
    }
  )
}

type VerifyTechnicianRequest = {
  status: "PASSED" | "FAILED"
  reason: string
}

export function useVerifyTechnician(technicianId: number) {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  return usePatch<unknown, VerifyTechnicianRequest>(
    `${URL_API}/admins/verification/technicians/${technicianId}/verification-status`,
    {
      headers: {
        Authorization: `Bearer ${token}`
      }
    }
  )
}

export function useGetVerificationDetail(technicianId: number) {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  return useFetch<TechnicianVerificationDetail>(
    `${URL_API}/admins/verification/technicians/${technicianId}/verification-detail`,
    ["verification-detail", String(technicianId)],
    undefined,
    undefined,
    {
      Authorization: `Bearer ${token}`
    }
  )
}
