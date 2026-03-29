import { AxiosError, AxiosHeaders, AxiosResponse } from "axios"
import {
  useMutation,
  useQuery,
  UseQueryOptions,
  UseMutationOptions
} from "@tanstack/react-query"
import { appAxios } from "@/core/libs/axios"

export type QueryKeyT = [string, object | undefined]

export interface ApiError {
  message?: string
  [key: string]: unknown
}

export const useDefaultError = () => {
  return (error: AxiosError<ApiError>) => {
    const errorMessage =
      error.response?.data?.message ||
      JSON.stringify(error.response?.data) ||
      error.message

    console.log(errorMessage)
  }
}

interface FetcherParams {
  queryKey: QueryKeyT
  headers?: Record<string, string>
  isDirectData?: boolean
}

export const fetcher = async <T>({
  queryKey,
  headers,
  isDirectData = false
}: FetcherParams): Promise<T> => {
  const [url, params] = queryKey

  const res = await appAxios().get(url, {
    params,
    headers
  })

  return isDirectData ? res.data : res.data.data
}

export const useFetch = <T>(
  url: string,
  queryKey?: string[],
  params?: Record<string, any>, // ✅ เพิ่มตรงนี้
  initialData?: T,
  headers?: Record<string, string>
) => {
  return useQuery({
    queryKey: queryKey || [url, params], // ✅ include params กัน cache เพี้ยน
    queryFn: async () => {
      const response = await appAxios(
        headers ? { headers: new AxiosHeaders(headers) } : undefined
      ).get(url, {
        params // ✅ ส่งเข้า axios
      })

      return (response.data?.data || response.data) as T
    },
    initialData,
    enabled: !!url
  })
}

export const useFetchWithCondition = <T>(
  url: string,
  queryKey?: string[],
  initialData?: T,
  headers?: Record<string, string>,
  enabled?: boolean
) => {
  return useQuery({
    queryKey: queryKey || [url],
    queryFn: async () => {
      const response = await appAxios(
        headers ? { headers: new AxiosHeaders(headers) } : undefined
      ).get(url)
      // Handle both wrapped and raw responses
      return (response.data?.data || response.data) as T
    },
    initialData,
    enabled: enabled
  })
}

//
// 🔥 FIX: Generic Mutation
//
const useGenericMutation = <TData = unknown, TVariables = unknown>(
  func: (data: TVariables) => Promise<AxiosResponse<TData>>,
  config?: UseMutationOptions<TData, AxiosError<ApiError>, TVariables>
) => {
  return useMutation<TData, AxiosError<ApiError>, TVariables>({
    mutationFn: async (data: TVariables) => {
      const res = await func(data)
      return res.data
    },
    onError: useDefaultError(),
    ...config
  })
}

//
// ✅ POST
//
export const usePost = <TData = unknown, TVariables = unknown>(
  url: string,
  config?: UseMutationOptions<TData, AxiosError<ApiError>, TVariables> & {
    headers?: Record<string, string>
  }
) => {
  return useGenericMutation<TData, TVariables>(
    (data) =>
      appAxios().post<TData>(url, data, {
        headers: config?.headers
      }),
    config
  )
}

//
// ✅ PUT
//
export const usePut = <TData = unknown, TVariables = unknown>(
  url: string,
  config?: UseMutationOptions<TData, AxiosError<ApiError>, TVariables>
) => {
  return useGenericMutation<TData, TVariables>(
    (data) => appAxios().put<TData>(url, data),
    config
  )
}

//
// ✅ PATCH
//
export const usePatch = <TData = unknown, TVariables = unknown>(
  url: string,
  config?: UseMutationOptions<TData, AxiosError<ApiError>, TVariables> & {
    headers?: Record<string, string>
  }
) => {
  return useGenericMutation<TData, TVariables>(
    (data) =>
      appAxios().patch<TData>(url, data, {
        headers: config?.headers
      }),
    config
  )
}

//
// ✅ DELETE
//
export const useDelete = <TData = unknown>(
  url: string,
  config?: UseMutationOptions<TData, AxiosError<ApiError>, void>
) => {
  return useMutation<TData, AxiosError<ApiError>, void>({
    mutationFn: async () => {
      const res = await appAxios().delete<TData>(url)
      return res.data
    },
    onError: useDefaultError(),
    ...config
  })
}
