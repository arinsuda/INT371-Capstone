"use client"

import { useState } from "react"
import Link from "next/link"
import ArrowBackIosIcon from "@mui/icons-material/ArrowBackIos"
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos"
import { useGetTechnicianResponse } from "@/data/api/technicians.hook"

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
  const [selectedStatus, setSelectedStatus] = useState("ทั้งหมด")
  const mapStatusToAPI = (status: string) => {
    switch (status) {
      case "รอการตรวจสอบ":
        return "PENDING"
      case "ไม่ผ่าน":
        return "FAILED"
      default:
        return undefined // 👈 "ทั้งหมด" = ไม่ส่ง
    }
  }
  const { data: technicianResponseData } = useGetTechnicianResponse(undefined, {
    verification_status: mapStatusToAPI(selectedStatus)
  })
  const statusTabs = ["ทั้งหมด", "รอการตรวจสอบ", "ไม่ผ่าน"]

  const verifyOrder: Record<string, number> = {
    ผ่านการตรวจสอบ: 1,
    รอการตรวจสอบ: 2,
    ไม่ผ่าน: 3
  }

  const mapStatus = (status: string) => {
    switch (status) {
      case "PENDING":
        return "รอการตรวจสอบ"
      case "FAILED":
        return "ไม่ผ่าน"
      default:
        return "ผ่านการตรวจสอบ"
    }
  }

  const technicians = technicianResponseData?.technicians || []

  const sortedTechnicians = [...technicians].sort((a, b) => {
    return (
      verifyOrder[mapStatus(a.verification_status)] -
      verifyOrder[mapStatus(b.verification_status)]
    )
  })

  const filteredTechnicians = sortedTechnicians.filter(
    (tech) => mapStatus(tech.verification_status) !== "ผ่านการตรวจสอบ"
  )

  const currentData = filteredTechnicians
  const total = currentData.length
  const totalPages = technicianResponseData?.total_pages || 1

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

      <div className="flex gap-2">
        {statusTabs.map((status) => (
          <button
            key={status}
            onClick={() => {
              setSelectedStatus(status)
              setCurrentPage(1)
            }}
            className={`px-4 py-1 rounded-md text-sm border cursor-pointer ${
              selectedStatus === status
                ? "bg-[#EDF9FF] text-primary border-primary"
                : "bg-white text-black border-gray-300"
            }`}
          >
            {status}
          </button>
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
                    {tech.firstname} {tech.lastname}
                  </Link>
                </td>

                <td className="px-2 py-3">{tech.email}</td>
                <td className="px-4 py-3">{tech.phone}</td>
                <td className="px-4 py-3 max-w-40 truncate">
                  {tech.service_summary
                    ?.map((s) => s.service_category_name)
                    .join(" / ")}
                </td>
                <td className="px-4 py-3">
                  {tech.provinces?.map((p) => p.name_th).join(", ") || "-"}
                </td>
                <td className="px-4 py-3">12</td>
                <td className="px-4 py-3">
                  <span
                    className={`px-2 py-px rounded-md text-[12px] font-medium ${statusColor(
                      mapStatus(tech.verification_status)
                    )}`}
                  >
                    {mapStatus(tech.verification_status)}
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
