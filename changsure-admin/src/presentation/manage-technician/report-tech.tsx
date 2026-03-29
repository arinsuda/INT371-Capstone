"use client"

import { useState } from "react"
import Image from "next/image"
import Link from "next/link"
import ArrowBackIosIcon from "@mui/icons-material/ArrowBackIos"
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos"
import {
  CircleAlert,
  FileUser,
  Image as Gallery,
  Flag,
  TriangleAlert,
  Ban,
  ChevronDown
} from "lucide-react"
import { useRouter } from "next/navigation"
import {
  useGetTechnicianById,
  useGetTechnicianPostById,
  useGetTechnicianReportTypes,
  useReportTechnicianPost
} from "@/data/api/technicians.hook"
import { useSearchParams } from "next/navigation"
import { useGetAdminProfile } from "@/data/api/login.hook"
const images = [1, 2, 3, 4, 5] // mock

export const ReportTech = ({ id }: { id: number }) => {
  const [page, setPage] = useState(1)
  const perPage = 4
  const searchParams = useSearchParams()
  const postId = searchParams.get("postId")
  const postIdNumber = postId ? Number(postId) : null
  const { data: activityData } = useGetTechnicianPostById(id, postIdNumber || 0)
  const { data: technician } = useGetTechnicianById(id)
  const { data: reportTypes } = useGetTechnicianReportTypes(id)
  const { data: admin } = useGetAdminProfile()
  const [currentPage, setCurrentPage] = useState(1)
  const router = useRouter()
  const { mutate } = useReportTechnicianPost(id, postIdNumber || 0)
  const [reportType, setReportType] = useState(reportTypes?.[0] || "")
  const [reason, setReason] = useState("")
  const [severity, setSeverity] = useState<"WARNING" | "BLACKLIST">("WARNING")
  const [deletePost, setDeletePost] = useState(true)

  const handleSubmit = () => {
    mutate({
      report_type: reportType,
      severity: severity,
      ...(reason ? { reason } : {}),
      ...(deletePost !== undefined ? { delete_post: deletePost } : {})
    })
  }

  const images = Array.isArray(activityData?.images) ? activityData.images : []

  const start = (page - 1) * perPage
  const currentImages = images.slice(start, start + perPage)
  const totalPages = Math.ceil(images.length / perPage)

  console.log("postId", postId)
  console.log("activityData", activityData)

  const formatDateTime = (timestamp: number) => {
    const date = new Date(timestamp * 1000)

    const day = String(date.getDate()).padStart(2, "0")
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const year = date.getFullYear()

    return `${day}/${month}/${year}`
  }

  const [warnStatus, setWarnStatus] = useState<"warning" | "blacklist">(
    "warning"
  )

  return (
    <div className="p-6 space-y-6">
      {/* Breadcrumb */}
      <div className="text-sm text-black/60 flex items-center gap-1">
        <Link href="/manage-technicians" className="underline">
          จัดการข้อมูลช่าง
        </Link>
        <ArrowForwardIosIcon sx={{ fontSize: 14 }} />
        <Link href={`/manage-technicians/${id}`} className="underline">
          ข้อมูลช่าง
        </Link>
        <ArrowForwardIosIcon sx={{ fontSize: 14 }} />
        <span className="text-black">รายงานผลงาน</span>
      </div>

      {/* Title */}
      <div>
        <div className="text-lg font-semibold flex items-center gap-2">
          <CircleAlert className="w-5 h-5" />{" "}
          <p className="text-[18px]">รายงานผลงานไม่เหมาะสม</p>
        </div>
        <p className="text-[14px] text-colorTertiaryText mt-1">
          กรุณาระบุรายละเอียดของปัญหาที่พบในผลงานชิ้นนี้
          ข้อมูลจะถูกบันทึกเพื่อใช้ในการตรวจสอบและดำเนินการตามนโยบายของระบบ
          ChangSure
        </p>
      </div>

      {/* Card */}
      <div className="bg-white rounded-2xl p-6 border border-colorStroke space-y-6">
        {/* Work Info */}
        <div className="space-y-4">
          <div className="flex items-center gap-2">
            <FileUser className="w-6 h-6" />
            <h3 className="font-medium text-[18px]">ข้อมูลผลงานที่ถูกรายงาน</h3>
          </div>

          <div className="flex flex-col gap-1 pt-4">
            <p className="text-[16px] text-colorTertiaryText">
              ชื่อเจ้าของผลงาน
            </p>
            <input
              className="w-full border border-colorStroke rounded-lg px-3 py-2 text-[16px] text-primaryBorder"
              placeholder="ชื่อเจ้าของผลงาน"
              defaultValue={
                technician?.firstname && technician?.lastname
                  ? `${technician.firstname} ${technician.lastname}`
                  : "นายสมชาย ใจดี"
              }
              disabled
            />
          </div>

          <div className="grid grid-cols-2 gap-4 pt-2">
            <div className="flex flex-col gap-1 ">
              <p className="text-[16px] text-colorTertiaryText">ประเภทงาน</p>
              <input
                className="border rounded-lg border-colorStroke px-3 py-2 text-[16px] text-primaryBorder"
                placeholder="ประเภทงาน"
                defaultValue={activityData?.category_name || ""}
                disabled
              />
            </div>
            <div className="flex flex-col gap-1 ">
              <p className="text-[16px] text-colorTertiaryText">วันที่โพสต์</p>
              <input
                className="border rounded-lg border-colorStroke px-3 py-2 text-[16px] text-primaryBorder"
                placeholder="วันที่โพสต์"
                defaultValue={
                  activityData?.created_at
                    ? formatDateTime(activityData.created_at)
                    : ""
                }
                disabled
              />
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <p className="text-[16px] text-colorTertiaryText">
              รายละเอียดเพิ่มเติม (ถ้ามี)
            </p>

            <div className="relative">
              <textarea
                value={activityData?.description}
                maxLength={500}
                disabled
                className="w-full border rounded-lg px-3 py-2 text-[16px] h-30 
                     text-primaryBorder border-colorStroke
                     resize-none overflow-y-auto pr-16"
              />

              {/* Counter */}
              <span className="absolute bottom-3 right-3 text-xs text-black/40">
                {activityData?.description.length}/500
              </span>
            </div>
          </div>
        </div>

        {/* Images */}
        <div className="border space-y-6 rounded-lg border-colorStroke ">
          <div className="border-b border-colorStroke px-5 py-3 flex items-center gap-2 text-colorTertiaryText">
            <Gallery className="w-4 h-4" />
            <p className="text-[16px]">รูปภาพผลงานช่าง</p>
          </div>

          <div className="grid grid-cols-4 gap-3 px-5">
            {currentImages.length > 0 ? (
              currentImages.map((img) => {
                const imageUrl =
                  typeof img.image_url === "string" &&
                  img.image_url.trim() !== ""
                    ? img.image_url
                    : "/images/no_image.png"

                return (
                  <div key={img.id} className="w-full h-35 relative">
                    <Image
                      src={imageUrl}
                      alt="work"
                      fill
                      className="rounded-lg object-cover"
                    />
                  </div>
                )
              })
            ) : (
              <div className="col-span-4 text-center text-gray-400 text-sm">
                ไม่มีรูปภาพ
              </div>
            )}
          </div>

          <div className="flex justify-between px-5 pb-4 items-center">
            <p className="text-xs text-black/40">
              จำนวนภาพทั้งหมด {images.length}/{images.length}
            </p>

            <div className="flex items-center gap-1">
              {/* Prev */}
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage((p) => p - 1)}
                className="disabled:opacity-30 disabled:cursor-not-allowed"
              >
                <ArrowBackIosIcon
                  className="text-black cursor-pointer"
                  sx={{ fontSize: 14 }}
                />
              </button>

              {/* Pages */}
              {Array.from({ length: totalPages }).map((_, i) => {
                const page = i + 1
                const isActive = currentPage === page

                return (
                  <button
                    key={page}
                    onClick={() => setCurrentPage(page)}
                    className={`px-3 py-1 text-[14px] rounded-md transition
                  ${
                    isActive
                      ? "border border-[#0F52BA] text-[#0F52BA]"
                      : "text-black/70"
                  }`}
                  >
                    {page}
                  </button>
                )
              })}

              {/* Next */}
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage((p) => p + 1)}
                className="disabled:opacity-30 disabled:cursor-not-allowed"
              >
                <ArrowForwardIosIcon
                  className="text-black cursor-pointer"
                  sx={{ fontSize: 14 }}
                />
              </button>
            </div>
          </div>
        </div>

        {/* Report Detail */}
        <div className="space-y-6">
          <div className="flex items-center gap-2">
            <Flag className="w-4 h-4" />
            <h3 className="font-medium text-[18px]">รายละเอียดการรายงาน</h3>
          </div>

          <div className="flex flex-col gap-1">
            <p className="text-colorTertiaryText">ประเภทการรายงาน</p>
            <div className="relative w-2/5">
              <select
                value={reportType}
                onChange={(e) => setReportType(e.target.value)}
                className="w-full appearance-none border border-colorStroke rounded-lg px-3 pr-10 py-2 text-[16px] focus:outline-none focus:border-primaryBorderHover focus:ring-1 focus:ring-primaryBorderHover"
              >
                {reportTypes?.map((type, i) => (
                  <option key={i} value={type}>
                    {type}
                  </option>
                ))}
              </select>

              {/* custom arrow */}
              <span className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-black/40">
                <ChevronDown className="w-4 h-4" />
              </span>
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <p className="text-colorTertiaryText">
              รายละเอียดเพิ่มเติม (ถ้ามี)
            </p>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="w-2/5 resize-none border border-colorStroke rounded-lg px-3 py-2 text-[16px] h-28 focus:outline-none focus:border-primaryBorderHover focus:ring-1 focus:ring-primaryBorderHover"
              placeholder=""
            />
            <p className="text-primaryBorder text-[14px]">
              โปรดอธิบายปัญหาที่พบในผลงานนี้ เช่น ภาพไม่เหมาะสม
              หรือไม่ใช่ผลงานจริงของช่าง
            </p>
          </div>

          {/* Action Level */}
          <div className="space-y-2">
            <p className="text-[16px] text-colorTertiaryText">
              ระดับการดำเนินการ
            </p>

            <div className="flex gap-4">
              <label className="flex flex-col items-start gap-2 text-[16px] border border-colorStroke rounded-lg px-4 py-3 w-full cursor-pointer">
                <div className="flex justify-between items-center gap-2 w-full">
                  <div className="flex items-center gap-2">
                    <TriangleAlert className="w-4 h-4" />
                    <span>ตักเตือน (Warning)</span>
                  </div>

                  <input
                    type="checkbox"
                    checked={severity === "WARNING"}
                    onChange={() => setSeverity("WARNING")}
                    className="w-4 h-4 accent-secondary"
                  />
                </div>

                <p className="text-[14px] text-primaryBorder">
                  ใช้สำหรับกรณีทำความผิดครั้งแรก มีความผิดเล็กน้อย
                  ช่างยังสามารถใช้งานระบบได้
                </p>
              </label>

              <label className="flex flex-col items-start gap-2 text-[16px] border border-colorStroke rounded-lg px-4 py-3 w-full cursor-pointer">
                <div className="flex justify-between items-center gap-2 w-full">
                  <div className="flex items-center gap-2">
                    <Ban className="w-4 h-4" />
                    <span>ระงับการใช้งาน (Blacklist)</span>
                  </div>

                  <input
                    type="checkbox"
                    checked={severity === "BLACKLIST"}
                    onChange={() => setSeverity("BLACKLIST")}
                    className="w-4 h-4 accent-secondary"
                  />
                </div>
                <p className="text-[14px] text-primaryBorder">
                  ใช้สำหรับกรณีร้ายแรงหรือเป็นการกระทำซ้ำ
                </p>
              </label>
            </div>
          </div>

          {/* Remove Work */}
          <label className="flex items-center gap-2 text-[16px]">
            <input
              type="checkbox"
              className="w-4 h-4 accent-secondary"
              checked={deletePost}
              onChange={(e) => setDeletePost(e.target.checked)}
            />
            ลบผลงานนี้ออกจากระบบ
          </label>

          {/* Admin */}
          <div className="flex flex-col gap-1">
            <p className="text-[16px] text-colorTertiaryText">
              Admin ที่ดำเนินการ
            </p>
            <input
              className="w-2/5 border border-colorStroke rounded-lg px-3 py-2 text-[16px] text-colorTertiaryText"
              defaultValue={
                admin ? `${admin.first_name} ${admin.last_name}` : ""
              }
              disabled
            />
          </div>
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-3 pt-4 text-[18px]">
          <button
            onClick={() => router.back()}
            className="px-20 py-1 rounded-lg border text-colorTertiaryText border-colorStroke bg-[#F6F7F9] cursor-pointer "
          >
            ยกเลิก
          </button>
          <button
            onClick={handleSubmit}
            className="px-20 py-1 rounded-lg bg-primary text-white cursor-pointer"
          >
            ยืนยัน
          </button>
        </div>
      </div>
    </div>
  )
}
