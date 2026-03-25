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
  TechnicianStats
} from "@/data/domain/technicians.domain"
const URL_API =
  process.env.NEXT_PUBLIC_URL_API ||
  "https://bscit.sit.kmutt.ac.th/capstone25/cp25ssa1/core-service/api"

export function useGetTechnicianStats() {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null
  return useFetch<TechnicianStats>(
    `${URL_API}/verification/stats`, // ✅ url
    undefined, // ✅ params (ไม่มี = undefined)
    undefined, // config
    {
      Authorization: `Bearer ${token}`
    }
  )
}

export function useGetTechnicianResponse() {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null
  const adminID =
    typeof window !== "undefined" ? localStorage.getItem("adminID") : null
  return useFetch<TechnicianResponse>(
    `${URL_API}/admins/${adminID}/technicians`, // ✅ url
    undefined, // ✅ params (ไม่มี = undefined)
    undefined, // config
    {
      Authorization: `Bearer ${token}`
    }
  )
}
