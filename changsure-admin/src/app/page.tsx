"use client"

import { useEffect } from "react"
import { useRouter } from "next/navigation"
import { LoginPage } from "@/presentation/login/Login"

export default function Home() {
  const router = useRouter()

  useEffect(() => {
    const token = localStorage.getItem("token")

    if (token) {
      router.replace("/manage-technicians")
    }
  }, [])

  return <LoginPage />
}
