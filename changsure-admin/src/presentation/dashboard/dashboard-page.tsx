"use client"

import { useState } from "react"
import { Users, Clock } from "lucide-react"
import VerifiedRoundedIcon from "@mui/icons-material/VerifiedRounded"
import ReportIcon from "@mui/icons-material/Report"
import ArrowBackIosIcon from "@mui/icons-material/ArrowBackIos"
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos"
import Link from "next/link"
import { technicians } from "@/data/mock/technicians"
import {
  useGetTechnicianResponse,
  useGetTechnicianStats
} from "@/data/api/technicians.hook"

const statusColor = (status: string) => {
  switch (status) {
    case "ปกติ":
      return "bg-[#F6FFED] text-[#52C41A] border border-[#B7EB8F]"
    case "ตักเตือน":
      return "bg-[#FFFBE6] text-[#FFAD14] border border-[#FFE58F]"
    case "แบนถาวร":
      return "bg-[#FFF1F0] text-[#F5222D] border border-[#FFA39E]"
    default:
      return "bg-gray-100 text-gray-600"
  }
}

export const DashboardPage = () => {
  const { data: statsData } = useGetTechnicianStats()

  const mappedStats = [
    {
      title: "จำนวนช่างทั้งหมด",
      value: statsData?.total ?? 0,
      icon: <Users className="text-[#9254DE]" />,
      bg: "bg-[#E8DBF8]"
    },
    {
      title: "ช่างรอตรวจสอบ",
      value: statsData?.pending ?? 0,
      icon: <Clock className="text-[#FFC53D]" />,
      bg: "bg-[#FFEEC5]"
    },
    {
      title: "ช่างที่ผ่านการรับรองแล้ว",
      value: statsData?.passed ?? 0,
      icon: <VerifiedRoundedIcon className="text-[#1677FF]" />,
      bg: "bg-[#CEE2FF]"
    },
    {
      title: "ช่างถูกรายงาน",
      value: statsData?.failed ?? 0,
      icon: <ReportIcon className="text-colorError" />,
      bg: "bg-[#FFCACA]"
    }
  ]

  const statusOrder: Record<string, number> = {
    ปกติ: 1,
    ตักเตือน: 2,
    แบนถาวร: 3
  }

  const mapStatus = (status: string) => {
    switch (status) {
      case "PASSED":
        return "ปกติ"
      case "PENDING":
        return "ตักเตือน"
      case "FAILED":
        return "แบนถาวร"
      default:
        return "ปกติ"
    }
  }


  return (
    <div className="p-6 space-y-6">
      <h1 className="text-lg font-bold">จัดการข้อมูลช่าง</h1>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {mappedStats.map((item, index) => (
          <div
            key={index}
            className="flex items-center justify-between p-6 bg-white rounded-[20px]"
          >
            <div className="flex flex-col gap-2">
              <p className="text-sm text-primary/70">{item.title}</p>
              <p className="text-2xl font-bold">
                {item.value}{" "}
                <span className="text-lg text-colorTertiaryText font-medium">
                  คน
                </span>
              </p>
            </div>
            <div className={`p-3 rounded-2xl ${item.bg}`}>{item.icon}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
