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
const URL_API =
  process.env.NEXT_PUBLIC_URL_API ||
  "https://bscit.sit.kmutt.ac.th/capstone25/cp25ssa1/core-service/api"

export function useSendForm(
  options?: UseMutationOptions<any, Error, LoginRequest>
) {
  return usePost(`${URL_API}/auth/login`, options)
}

export function useGetAdminProfile() {
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  const adminId =
    typeof window !== "undefined" ? localStorage.getItem("adminId") : null

  return useFetch<Admin>(
    `${URL_API}/admins/${adminId}/profile`, // ✅ url
    undefined, // ✅ params (ไม่มี = undefined)
    undefined, // config
    undefined, // initialData
    {
      Authorization: `Bearer ${token}`
    }
  )
}
