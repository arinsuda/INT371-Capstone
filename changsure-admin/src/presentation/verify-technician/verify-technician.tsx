"use client"

import { useState } from "react"
import VerifiedRoundedIcon from "@mui/icons-material/VerifiedRounded"
import { Users, Clock } from "lucide-react"
import { technicians } from "@/data/mock/technicians"
import Link from "next/link"
import ArrowBackIosIcon from "@mui/icons-material/ArrowBackIos"
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos"
import { useGetTechnicianStats } from "@/data/api/technicians.hook"

const statusColor = (verify: string) => {
  switch (verify) {
    case "ผ่านการตรวจสอบ":
      return "bg-[#F6FFED] text-[#52C41A] border border-[#B7EB8F]"
    case "รอการตรวจสอบ":
      return "bg-[#FFFBE6] text-[#FFAD14] border border-[#FFE58F]"
    case "ไม่ผ่าน":
      return "bg-[#FFF1F0] text-[#F5222D] border border-[#FFA39E]"
    default:
      return "bg-gray-100 text-gray-600"
  }
}

export const VerifyTechnicianPage = () => {
  const [currentPage, setCurrentPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const { data: statsData } = useGetTechnicianStats()

  const mappedStats = [
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
    }
  ]

  const verifyOrder: Record<string, number> = {
    ผ่านการตรวจสอบ: 1,
    รอการตรวจสอบ: 2,
    ไม่ผ่าน: 3
  }

  // sort ก่อน pagination
  const sortedTechnicians = [...technicians].sort(
    (a, b) => verifyOrder[a.verify] - verifyOrder[b.verify]
  )

  const total = sortedTechnicians.length
  const totalPages = Math.ceil(total / pageSize)

  const startIndex = (currentPage - 1) * pageSize
  const currentData = sortedTechnicians.slice(startIndex, startIndex + pageSize)

  const visiblePages = 3

  let startPage = Math.max(1, currentPage - 1)
  let endPage = startPage + visiblePages - 1

  if (endPage > totalPages) {
    endPage = totalPages
    startPage = Math.max(1, endPage - visiblePages + 1)
  }

  const pages = []
  for (let i = startPage; i <= endPage; i++) {
    pages.push(i)
  }

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-lg font-bold">รายชื่อผู้สมัครช่าง</h1>

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

      {/* Table */}
      <div className="bg-white overflow-hidden">
        <table className="w-full text-[14px]">
          <thead className="bg-primaryBorderHover text-white">
            <tr>
              <th className="p-4 text-left border-r border-primaryHover">
                ชื่อ - นามสกุล
              </th>
              <th className="p-4 text-left border-r border-primaryHover">
                อีเมล
              </th>
              <th className="p-4 text-left border-r border-primaryHover">
                เบอร์โทรศัพท์
              </th>
              <th className="p-4 text-left border-r border-primaryHover">
                ประเภทงานที่สมัคร
              </th>
              <th className="p-4 text-left border-r border-primaryHover">
                พื้นที่ให้บริการ
              </th>
              <th className="p-4 text-left border-r border-primaryHover">
                วันที่สมัคร
              </th>
              <th className="p-4 text-left ">สถานะช่าง</th>
            </tr>
          </thead>

          <tbody>
            {currentData.map((tech) => (
              <tr
                key={tech.id}
                className="border-b border-colorStroke last:border-none"
              >
                <td className="px-4 py-3 text-primary font-medium cursor-pointer hover:bg-gray-50 text-[14px] hover:underline">
                  <Link
                    href={`/verify-technician/${tech.id}`}
                    className="block"
                  >
                    {tech.name}
                  </Link>
                </td>

                <td className="px-2 py-3">{tech.email}</td>
                <td className="px-4 py-3">{tech.phone}</td>
                <td className="px-4 py-3">{tech.type}</td>
                <td className="px-4 py-3">{tech.area}</td>
                <td className="px-4 py-3">{tech.date}</td>
                <td className="px-4 py-3">
                  <span
                    className={`px-2 py-px rounded-md text-[12px] font-medium ${statusColor(
                      tech.verify
                    )}`}
                  >
                    {tech.verify}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Footer Pagination (UI เดิม แต่เพิ่ม logic) */}
        <div className="flex items-center justify-end p-4 text-sm text-gray-500">
          <p className="px-4 text-black/85">Total {total} Rows</p>

          <div className="flex items-center gap-2">
            <div className="flex items-center gap-2">
              {/* Prev */}
              <ArrowBackIosIcon
                onClick={() =>
                  currentPage > 1 && setCurrentPage(currentPage - 1)
                }
                className={`${
                  currentPage > 1
                    ? "text-black cursor-pointer"
                    : "text-black/30"
                }`}
                sx={{ fontSize: 16 }}
              />

              {/* Pages (แสดงแค่ 3) */}
              {pages.map((page) => (
                <button
                  key={page}
                  onClick={() => setCurrentPage(page)}
                  className={`px-3 py-1 rounded-md cursor-pointer ${
                    currentPage === page
                      ? "border border-[#0F52BA] text-[#0F52BA]"
                      : "text-black"
                  }`}
                >
                  {page}
                </button>
              ))}

              {/* Next */}
              <ArrowForwardIosIcon
                onClick={() =>
                  currentPage < totalPages && setCurrentPage(currentPage + 1)
                }
                className={`${
                  currentPage < totalPages
                    ? "text-black cursor-pointer"
                    : "text-black/30"
                }`}
                sx={{ fontSize: 16 }}
              />
            </div>

            {/* Page size */}
            <select
              value={pageSize}
              onChange={(e) => {
                setPageSize(Number(e.target.value))
                setCurrentPage(1)
              }}
              className="border border-black/15 rounded-sm px-2 py-1 text-black"
            >
              <option value={10}>10 / หน้า</option>
              <option value={20}>20 / หน้า</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  )
}
