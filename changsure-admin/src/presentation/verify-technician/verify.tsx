"use client"

import Image from "next/image"
import { useRouter } from "next/navigation"
import Link from "next/link"
import EmailIcon from "@mui/icons-material/Email"
import LocalPhoneRoundedIcon from "@mui/icons-material/LocalPhoneRounded"
import FmdGoodIcon from "@mui/icons-material/FmdGood"
import WorkIcon from "@mui/icons-material/Work"
import ArrowForwardIosIcon from "@mui/icons-material/ArrowForwardIos"
import VerifiedUserIcon from "@mui/icons-material/VerifiedUser"
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth"
import { FileText } from "lucide-react"
import { useState } from "react"
import {
  useGetTechnicianById,
  useGetVerificationDetail,
  useVerifyTechnician
} from "@/data/api/technicians.hook"

export const Verify = ({ id }: { id: number }) => {
  const [crimeStatus, setCrimeStatus] = useState<"clean" | "crime">("clean")
  const { data: technician, isLoading } = useGetTechnicianById(id)
  const verifyTechnician = useVerifyTechnician(id)
  const { data: verificationDetail } = useGetVerificationDetail(id)

  console.log("verificationDetail", verificationDetail)

  const router = useRouter()

  if (!technician) {
    return <div>Technician not found</div>
  }

  const statusColor = (status: string) => {
    switch (status) {
      case "PASSED":
        return "bg-[#F6FFED] text-[#52C41A] border border-[#B7EB8F]"
      case "PENDING":
        return "bg-[#FFFBE6] text-[#FFAD14] border border-[#FFE58F]"
      case "FAILED":
        return "bg-[#FFF1F0] text-[#F5222D] border border-[#FFA39E]"
      default:
        return "bg-gray-100 text-gray-600"
    }
  }

  const mapStatus = (status: string) => {
    switch (status) {
      case "PASSED":
        return "ผ่านการตรวจสอบ"
      case "PENDING":
        return "รอการตรวจสอบ"
      case "FAILED":
        return "ไม่ผ่านการตรวจสอบ"
      default:
        return "ผ่านการตรวจสอบ"
    }
  }
  const formatDateTime = (timestamp: number) => {
    const date = new Date(timestamp * 1000)

    const day = String(date.getDate()).padStart(2, "0")
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const year = date.getFullYear()

    return `${day}/${month}/${year}`
  }

  return (
    <div className="p-6 space-y-6">
      <div className="text-sm text-black/60 flex items-center gap-1">
        <Link href="/verify-technician" className="underline">
          รายชื่อผู้สมัครช่าง
        </Link>
        <ArrowForwardIosIcon sx={{ fontSize: 14 }} />
        <p className="text-black">ตรวจสอบช่าง</p>
      </div>

      <div>
        <div className="text-lg font-semibold flex items-center gap-2">
          <VerifiedUserIcon sx={{ fontSize: 20 }} />{" "}
          <p className="text-[18px]">ตรวจสอบช่าง</p>
        </div>
        <p className="text-[14px] text-colorTertiaryText mt-1">
          กรุณาตรวจสอบความถูกต้องครบถ้วนของข้อมูลและเอกสารยืนยันตัวตนของผู้สมัครเป็นช่าง
          เพื่อพิจารณาอนุมัติการเข้าใช้งานระบบตามข้อกำหนดของ ChangSure
        </p>
      </div>

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
              <h2 className="text-xl font-semibold">
                {technician.firstname} {technician.lastname}
              </h2>
              <span
                className={`px-2 py-px text-xs rounded-md ${statusColor(technician.verification_status)}`}
              >
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

        <hr className="text-colorStroke" />

        {/* Detail Box */}
        <div className="px-4 space-y-6 text-sm">
          <div className="flex items-center gap-2">
            <WorkIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />
            <span className="text-colorTertiaryText text-[14px]">
              ประเภทงาน
            </span>
            <span className="ml-5">
              {technician.service_summary
                .map((service) => service.service_category_name)
                .join("/")}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <FmdGoodIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />
            <span className="text-colorTertiaryText text-[14px]">
              พื้นที่ให้บริการ
            </span>
            <span className="ml-5">
              {technician.provinces.map((p) => p.name_th).join(", ")}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <CalendarMonthIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />
            <span className="text-colorTertiaryText text-[14px]">
              วันที่สมัคร
            </span>
            <span className="ml-5">
              {formatDateTime(technician.created_at)}
            </span>
          </div>
        </div>

        <hr className="text-colorStroke" />

        <div className="space-y-6">
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5" />
            <h3 className="font-bold text-[18px]">ข้อมูลบัตรประชาชน</h3>
          </div>

          <div className="flex gap-4 w-full">
            <div className="flex flex-col gap-1 w-full">
              <p className="text-colorTertiaryText">เลขที่บัตรประชาชน</p>
              <div className="relative w-full">
                <input
                  type="text"
                  className="border border-colorStroke w-full rounded-lg text-[16px] px-4 py-2 disabled:text-primaryBorder"
                  defaultValue={verificationDetail?.national_id || "-"}
                  disabled
                />
              </div>
            </div>

            <div className="flex flex-col gap-1 w-full">
              <p className="text-colorTertiaryText">ชื่อ - สกุล</p>
              <input
                type="text"
                className="border border-colorStroke w-full rounded-lg text-[16px] px-4 py-2 disabled:text-primaryBorder"
                defaultValue={
                  verificationDetail?.first_name +
                    " " +
                    verificationDetail?.last_name || "-"
                }
                disabled
              />
            </div>
          </div>

          <div className="flex flex-col gap-1 w-full">
            <p className="text-colorTertiaryText">รูปถ่ายบัตรประชาชน</p>

            <div className="relative w-2/5 aspect-16/10">
              <Image
                src={
                  verificationDetail?.id_card_image_url || "/capstone25/cp25ssa1/images/ID_Card.png"
                }
                alt="รูปถ่ายบัตรประชาชน"
                fill
                className="object-contain rounded-lg"
                unoptimized
              />
            </div>
          </div>

          {/* Action Level */}
          <div className="space-y-2">
            <p className="text-[16px] text-colorTertiaryText">
              การตรวจสอบประวัติอาชญากรรม
            </p>

            <div className="flex gap-4">
              <label className="flex flex-col items-start gap-2 text-[16px] border border-colorStroke rounded-lg px-4 py-3 w-full cursor-pointer">
                <div className="flex justify-between items-center gap-2 w-full">
                  <span>ไม่พบประวัติอาชญากรรม</span>

                  <input
                    type="checkbox"
                    checked={crimeStatus === "clean"}
                    onChange={() => setCrimeStatus("clean")}
                    className="w-4 h-4 accent-secondary"
                  />
                </div>

                <p className="text-[14px] text-primaryBorder">
                  สามารถดำเนินการอนุมัติการสมัครได้
                </p>
              </label>

              <label className="flex flex-col items-start gap-2 text-[16px] border border-colorStroke rounded-lg px-4 py-3 w-full cursor-pointer">
                <div className="flex justify-between items-center gap-2 w-full">
                  <span>พบประวัติอาชญากรรม</span>

                  <input
                    type="checkbox"
                    checked={crimeStatus === "crime"}
                    onChange={() => setCrimeStatus("crime")}
                    className="w-4 h-4 accent-secondary"
                  />
                </div>

                <p className="text-[14px] text-primaryBorder">
                  ไม่สามารถอนุมัติการสมัครได้
                </p>
              </label>
            </div>
          </div>

          {/* Admin */}
          <div className="flex flex-col gap-1">
            <p className="text-[16px] text-colorTertiaryText">
              Admin ที่ดำเนินการ
            </p>
            <input
              className="w-2/5 border border-colorStroke rounded-lg px-3 py-2 text-[16px] text-colorTertiaryText"
              defaultValue="วิชาญ จงกล"
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
            onClick={() => {
              const isClean = crimeStatus === "clean"

              verifyTechnician.mutate({
                status: isClean ? "PASSED" : "FAILED",
                reason: isClean ? "ไม่พบประวัติอาชญากรรม" : "พบประวัติอาชญากรรม"
              })

              router.push("/verify-technician")
            }}
            className="px-20 py-1 rounded-lg bg-primary text-white cursor-pointer"
          >
            ยืนยัน
          </button>
        </div>
      </div>
    </div>
  )
}
