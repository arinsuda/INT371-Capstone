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
import { technicianReports } from "@/data/mock/technicians"
import EmailIcon from "@mui/icons-material/Email"
import LocalPhoneRoundedIcon from "@mui/icons-material/LocalPhoneRounded"
import FmdGoodIcon from "@mui/icons-material/FmdGood"
import CreateIcon from "@mui/icons-material/Create"
import WorkIcon from "@mui/icons-material/Work"
import StarRateRoundedIcon from "@mui/icons-material/StarRateRounded"
import { WorkDetailModal } from "./components/WorkDetailModal"
import {
  useGetTechnicianById,
  useGetTechnicianPostReports,
  useGetTechnicianPosts
} from "@/data/api/technicians.hook"

export const TechInfo = ({ id }: { id: number }) => {
  const { data: technician, isLoading } = useGetTechnicianById(id)
  const { data: postsData } = useGetTechnicianPosts(id)
  const { data: reportsData } = useGetTechnicianPostReports(id)
  const [selectedPostId, setSelectedPostId] = useState<number>(0)
  const reports = reportsData?.items || []

  const [activeTab, setActiveTab] = useState<"Manage" | "History">("Manage")

  const posts = postsData?.items || []

  const tabs = [
    { key: "Manage", label: "ข้อมูลช่าง" },
    { key: "History", label: "ประวัติการรายงานช่าง" }
  ]

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
  const mapStatus = (status: string) => {
    switch (status) {
      case "WARNING":
        return "ตักเตือน"
      case "BLACKLIST":
        return "แบนถาวร"
      default:
        return "ตักเตือน"
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

  const formatDate = (timestamp: number) => {
    const date = new Date(timestamp * 1000) // ⚠️ ต้อง *1000
    return date.toLocaleDateString("th-TH", {
      day: "numeric",
      month: "long",
      year: "numeric"
    })
  }
  const formatDateTime = (timestamp: number) => {
    const date = new Date(timestamp * 1000)

    const day = String(date.getDate()).padStart(2, "0")
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const year = date.getFullYear()

    return `${day}/${month}/${year}`
  }

  if (isLoading) return <div>กำลังโหลดข้อมูล...</div>
  if (!technician) return <div>ไม่พบข้อมูล</div>

  console.log("TECHNICIAN:", technician)

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
                  src={
                    technician?.avatar_url &&
                    technician.avatar_url.trim() !== ""
                      ? technician.avatar_url
                      : "/images/no_image.png" // fallback ถ้าไม่มี avatar
                  }
                  alt="avatar"
                  width={112}
                  height={112}
                  className="object-cover w-full h-full"
                />
              </div>

              {/* Info */}
              <div className="flex-1 space-y-2">
                <div className="flex items-center gap-3">
                  <h2 className="text-xl font-semibold">
                    {technician.firstname} {technician.lastname}
                  </h2>
                  <span className="px-2 py-px text-xs rounded-md bg-[#F6FFED] text-[#52C41A] border border-[#B7EB8F]">
                    {mapStatus(technician.verification_status)}
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
                  {technician.primary_address?.address_line} แขวง
                  {technician.primary_address?.sub_district_name}{" "}
                  {technician.primary_address?.district_name}{" "}
                  {technician.primary_address?.province_name}{" "}
                  {technician.primary_address?.postal_code}
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
                  <span className="ml-5">
                    <span className="ml-5">
                      {technician.service_summary
                        ?.map((s) => s.service_category_name)
                        .join(" / ")}
                    </span>
                  </span>
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
                {/* <div className="flex gap-2 flex-wrap items-center">
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
                </div> */}
              </div>
            </div>
          </div>

          {/* Stats */}
          <div className="flex flex-col gap-4">
            <h3 className="font-bold text-[18px]">สถิติช่าง</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {[
                {
                  label: "จำนวนงานทั้งหมด",
                  value: technician.total_jobs,
                  icons: FileText
                },
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
                </div>
              ))}
            </div>
          </div>

          {/* Portfolio */}
          <div>
            <h3 className="font-semibold mb-4 text-[18px]">ผลงานช่าง</h3>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {posts.length === 0 ? (
                <p className="text-sm text-gray-500">ยังไม่มีผลงาน</p>
              ) : (
                posts.map((post) => {
                  const rawImage =
                    Array.isArray(post.images) && post.images.length > 0
                      ? post.images[0].image_url
                      : undefined

                  console.log("POST:", post)
                  console.log("IMAGE:", rawImage)
                  const imageUrl =
                    typeof rawImage === "string" && rawImage.trim().length > 0
                      ? rawImage
                      : "/images/no_image.png"

                  return (
                    <div
                      key={post.id}
                      className="bg-white rounded-xl shadow-sm overflow-hidden"
                    >
                      <div className="relative">
                        <Image
                          src={imageUrl}
                          alt="work"
                          width={300}
                          height={200}
                          className="w-full h-40 object-cover"
                        />

                        <span className="absolute top-0 left-3 bg-[#FFF0F6] text-[#EB2F96] text-[16px] px-2 py-px rounded-b-lg">
                          {post.category_name}
                        </span>
                      </div>

                      <div className="px-4 py-3 space-y-4 text-sm">
                        <div className="flex flex-col gap-1">
                          <p className="line-clamp-2 text-colorTertiaryText">
                            {post.description}
                          </p>

                          <p className="text-[12px] text-primaryBorder">
                            {formatDate(post.created_at)}
                          </p>
                        </div>
                        <div className="flex gap-2 pt-2">
                          {" "}
                          <button
                            onClick={() => {
                              setSelectedPostId(post.id)
                              setOpenModal(true)
                            }}
                            className="flex-1 border border-colorStroke rounded-lg py-1 text-xs cursor-pointer"
                          >
                            {" "}
                            <Eye className="w-3 h-3 inline mr-1" />{" "}
                            ดูรายละเอียด{" "}
                          </button>{" "}
                          <Link
                            href={`/manage-technicians/${id}/report?postId=${post.id}`}
                            className="flex-1 bg-[#FF7A45] text-white rounded-lg py-1 text-xs flex justify-center items-center"
                          >
                            {" "}
                            <CircleAlert className="w-3 h-3 inline mr-1" />{" "}
                            รายงาน{" "}
                          </Link>{" "}
                        </div>
                      </div>
                    </div>
                  )
                })
              )}
            </div>
          </div>
        </>
      )}

      <WorkDetailModal
        open={openModal}
        onClose={() => setOpenModal(false)}
        postId={selectedPostId}
        technicianId={id}
      />

      {/* History Tab */}
      {activeTab === "History" &&
        (reports.length === 0 ? (
          <div className="p-6 flex flex-col items-center">
            <img
              src="/images/no_report.png"
              alt="No Reports"
              className="w-75 mb-4"
            />
            <p className="text-sm text-gray-500">ยังไม่มีประวัติการรายงาน</p>
          </div>
        ) : (
          <div className="flex flex-col">
            <p className="pb-6 text-[18px] font-bold">ประวัติการรายงาน</p>

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
                  {reports.map((report, index) => (
                    <tr
                      key={index}
                      className="border-b border-colorStroke last:border-none"
                    >
                      <td className="px-4 py-3 text-primary font-medium text-[14px]">
                        {report.reported_at
                          ? formatDateTime(report.reported_at)
                          : "-"}
                      </td>

                      <td className="px-2 py-4">{report.report_type}</td>

                      <td className="px-4 py-4">{report.reason || "-"}</td>

                      <td className="px-4 py-4">
                        <span
                          className={`px-2 py-px rounded-md text-[12px] font-medium ${statusColor(
                            mapStatus(report.severity)
                          )}`}
                        >
                          {mapStatus(report.severity)}
                        </span>
                      </td>

                      <td className="px-4 py-4">
                        {report.admin?.first_name} {report.admin?.last_name}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ))}
    </div>
  )
}
