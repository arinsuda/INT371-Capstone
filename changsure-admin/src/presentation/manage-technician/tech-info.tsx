"use client"

import Image from "next/image"
import {
  Award,
  FileText,
  CalendarCheck,
  CircleX,
  Star,
  Eye,
  CircleAlert
} from "lucide-react"
import { useState } from "react"
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos"
import Link from "next/link"
import { technicians, technicianReports } from "@/data/mock/technicians"
import EmailIcon from "@mui/icons-material/Email"
import LocalPhoneRoundedIcon from "@mui/icons-material/LocalPhoneRounded"
import FmdGoodIcon from "@mui/icons-material/FmdGood"
import CreateIcon from "@mui/icons-material/Create"
import WorkIcon from "@mui/icons-material/Work"
import StarRateRoundedIcon from "@mui/icons-material/StarRateRounded"
import { WorkDetailModal } from "./components/WorkDetailModal"

export const TechInfo = ({ id }: { id: number }) => {
  const technician = technicians.find((t) => t.id === id)

  if (!technician) return <div>ไม่พบข้อมูล</div>
  const tabs = [
    { key: "Manage", label: "ข้อมูลช่าง" },
    { key: "History", label: "ประวัติการรายงานช่าง" }
  ]

  const [activeTab, setActiveTab] = useState<"Manage" | "History">("Manage")
  const [openModal, setOpenModal] = useState(false)

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

  const renderTabs = () => (
    <div className="flex gap-6 border-b border-colorStroke">
      {tabs.map((tab) => (
        <button
          key={tab.key}
          onClick={() => setActiveTab(tab.key as "Manage" | "History")}
          className={`pb-2 text-sm transition cursor-pointer ${
            activeTab === tab.key
              ? "border-b-2 border-primary text-primary font-medium"
              : "text-black/50"
          }`}
        >
          {tab.label}
        </button>
      ))}
    </div>
  )

  return (
    <div className="p-6 space-y-6">
      {/* Breadcrumb */}
      <div className="text-sm text-black/60 flex items-center gap-1">
        <Link className="underline" href={"/manage-technicians"}>
          จัดการข้อมูลช่าง
        </Link>{" "}
        <ArrowForwardIosIcon sx={{ fontSize: 14, color: "primaryText" }} />
        <span className="text-black ">ข้อมูลช่าง</span>
      </div>

      {/* Tabs */}
      {renderTabs()}

      {/* Profile Card */}
      {activeTab === "Manage" && (
        <>
          <div className="bg-white rounded-lg p-6 border border-colorStroke space-y-6">
            <div className="flex gap-6">
              {/* Avatar */}
              <div className="w-28 h-28 rounded-full overflow-hidden bg-gray-200">
                <Image
                  src="https://i.pravatar.cc/150"
                  alt="avatar"
                  width={112}
                  height={112}
                  className="object-cover w-full h-full"
                />
              </div>

              {/* Info */}
              <div className="flex-1 space-y-2">
                <div className="flex items-center gap-3">
                  <h2 className="text-xl font-semibold">{technician.name}</h2>
                  <span className="px-2 py-px text-xs rounded-md bg-[#F6FFED] text-[#52C41A] border border-[#B7EB8F]">
                    {technician.status}
                  </span>
                </div>

                <div className="flex items-center gap-6 text-sm text-black/70 pt-2">
                  <div className="flex items-center gap-2">
                    <EmailIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />{" "}
                    {technician.email}
                  </div>
                  <div className="flex items-center gap-2">
                    <LocalPhoneRoundedIcon
                      sx={{ fontSize: 16, color: "#9B9B9B" }}
                    />
                    {technician.phone}
                  </div>
                </div>

                <div className="flex items-center gap-2 text-sm text-black/70 pt-1">
                  <FmdGoodIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />
                  {technician.area}
                </div>
              </div>
            </div>

            {/* Detail Box */}
            <div className="border border-colorStroke rounded-xl overflow-hidden">
              <div className="bg-gray-100 px-6 py-3 text-[18px] text-colorTertiaryText border-b border-colorStroke">
                ข้อมูลช่าง
              </div>

              <div className="p-4 space-y-3 text-sm">
                <div className="flex items-center gap-2">
                  <WorkIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />
                  <span className="text-colorTertiaryText text-[14px]">
                    ประเภทงาน
                  </span>
                  <span className="ml-5">การไฟฟ้า / ทาสี</span>
                </div>

                <div className="flex items-center gap-2">
                  <FmdGoodIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />
                  <span className="text-colorTertiaryText text-[14px]">
                    พื้นที่ให้บริการ
                  </span>
                  <span className="ml-5">กรุงเทพมหานคร</span>
                </div>

                <div className="flex items-start gap-2">
                  <CreateIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />
                  <span className="text-colorTertiaryText text-[14px]">
                    เกี่ยวกับ
                  </span>
                  <span className="ml-5">
                    ใช้เฉพาะวัสดุคุณภาพดีและปลอดภัย เน้นงานเรียบร้อย
                    งานบ้านและคอนโด ขนาดเล็กถึงกลาง
                  </span>
                </div>

                {/* Tags */}
                <div className="flex gap-2 flex-wrap items-center">
                  <div className="flex items-center gap-2 pr-3">
                    <Award className="w-4 h-4 text-colorTertiaryText" />
                    <span className="text-colorTertiaryText text-[14px]">
                      ป้ายสัญลักษณ์
                    </span>
                  </div>
                  {[
                    "Top Service",
                    "ChangSure Recommend",
                    "High-Rating",
                    "Fast Response"
                  ].map((tag, i) => (
                    <span
                      key={i}
                      className="px-4 py-1 text-xs rounded-[10px] bg-primaryBGHover border border-colorStroke text-black"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Stats */}
          <div className="flex flex-col gap-4">
            <h3 className="font-bold text-[18px]">สถิติช่าง</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[
                { label: "จำนวนงานทั้งหมด", value: 20, icons: FileText },
                { label: "งานสำเร็จ", value: 19, icons: CalendarCheck },
                {
                  label: "งานที่ถูกยกเลิก",
                  value: 0,
                  icons: CircleX
                },
                {
                  label: "ค่า Rating เฉลี่ย",
                  value: "4.9",
                  icons: Star,
                  isRating: true
                }
              ].map((item, i) => (
                <div key={i} className="bg-white rounded-xl shadow-sm">
                  {/* Header */}
                  <div className="flex gap-3 items-center px-4 py-3">
                    <item.icons className="w-10 h-10 text-[#3071C7] bg-[#EDF9FF] rounded-md p-2.5" />
                    <p className="text-[16px] text-black">{item.label}</p>
                  </div>

                  {/* Value */}
                  <div className="flex gap-2 items-center px-4 py-3">
                    {item.isRating ? (
                      <div className="flex items-center gap-1">
                        <StarRateRoundedIcon
                          className="text-[#FFC53D]"
                          sx={{ fontSize: 32 }}
                        />
                        <p className="text-[32px] font-bold">{item.value}</p>
                        <p className="text-[16px] text-colorTertiaryText">
                          / 5
                        </p>
                      </div>
                    ) : (
                      <>
                        <p className="text-[32px] font-bold">{item.value}</p>
                        <p className="text-[16px] text-colorTertiaryText">
                          งาน
                        </p>
                      </>
                    )}
                  </div>

                  {/* Footer */}
                  <p className="text-xs text-black/40 border-t border-colorStroke px-4 py-2">
                    อัปเดตวันที่ 12/02/26
                  </p>
                </div>
              ))}
            </div>
          </div>

          {/* Portfolio */}
          <div>
            <h3 className="font-semibold mb-4 text-[18px]">ผลงานช่าง</h3>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[1, 2, 3, 4, 5].map((item) => (
                <div
                  key={item}
                  className="bg-white rounded-xl shadow-sm overflow-hidden"
                >
                  <div className="relative">
                    <Image
                      src="https://picsum.photos/300/200"
                      alt="work"
                      width={300}
                      height={200}
                      className="w-full h-40 object-cover"
                    />
                    <span className="absolute top-0 left-3 bg-[#FFF0F6] text-[#EB2F96] text-[16px] px-2 py-px rounded-b-lg">
                      ทาสี
                    </span>
                  </div>

                  <div className="px-4 py-3 space-y-4 text-sm">
                    <div className="flex flex-col gap-1">
                      <p className="line-clamp-2 text-colorTertiaryText">
                        ใช้วัสดุคุณภาพดีและปลอดภัย งานเรียบร้อย ลูกค้าพึงพอใจ
                        ทำออกมาได้ดีมากครับ
                      </p>
                      <p className="text-[12px] text-primaryBorder">
                        12 กุมภาพันธ์ 2569
                      </p>
                    </div>

                    <div className="flex gap-2 pt-2">
                      <button
                        onClick={() => setOpenModal(true)}
                        className="flex-1 border border-colorStroke rounded-lg py-1 text-xs items-center cursor-pointer"
                      >
                        <Eye className="w-3 h-3 inline mr-1" />
                        <span>ดูรายละเอียด</span>
                      </button>
                      <Link
                        href={`/manage-technicians/${technician.id}/report`}
                        className="flex-1 bg-[#FF7A45] text-white rounded-lg py-1 text-xs justify-center flex items-center"
                      >
                        <CircleAlert className="w-3 h-3 inline mr-1" />
                        รายงาน
                      </Link>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </>
      )}

      <WorkDetailModal open={openModal} onClose={() => setOpenModal(false)} />

      {/* History Tab */}
      {activeTab === "History" && (
        <div className="flex flex-col">
          <p className="pb-6 text-[18px] font-bold">ประวัติการรายงาน</p>

          {/* table */}
          <div className="bg-white overflow-hidden">
            <table className="w-full text-[14px]">
              <thead className="bg-primaryBorderHover text-white">
                <tr>
                  <th className="p-4 text-left border-r border-primaryHover">
                    วันที่รายงาน
                  </th>
                  <th className="p-4 text-left border-r border-primaryHover">
                    ประเภทการรายงาน
                  </th>
                  <th className="p-4 text-left border-r border-primaryHover">
                    เหตุผล
                  </th>
                  <th className="p-4 text-left border-r border-primaryHover">
                    ระดับโทษ (Warning / Blacklist)
                  </th>
                  <th className="p-4 text-left border-r border-primaryHover">
                    Admin ผู้ดำเนินการ
                  </th>
                </tr>
              </thead>
              <tbody>
                {technicianReports.map(
                  (report, index) => (
                    console.log(report.date),
                    (
                      <tr
                        key={index}
                        className="border-b border-colorStroke last:border-none "
                      >
                        <td className="px-4 py-3 text-primary font-medium cursor-pointer hover:bg-gray-50 text-[14px] hover:underline">
                          {report.date}
                        </td>

                        <td className="px-2 py-4">{report.type}</td>
                        <td className="px-4 py-4">{report.reason}</td>
                        <td className="px-4 py-4">
                          {" "}
                          <span
                            className={`px-2 py-px rounded-md text-[12px] font-medium ${statusColor(
                              report.level
                            )}`}
                          >
                            {report.level}
                          </span>
                        </td>
                        <td className="px-4 py-4">{report.admin}</td>
                      </tr>
                    )
                  )
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  )
}
