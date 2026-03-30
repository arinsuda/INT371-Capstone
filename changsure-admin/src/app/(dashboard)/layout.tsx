"use client"
import { DashboardLayoutUI } from "@/core/component/navbar"
import { ReactNode } from "react"


export default function DashboardLayout({ children }: { children: ReactNode }) {
  return <DashboardLayoutUI>{children}</DashboardLayoutUI>
}
