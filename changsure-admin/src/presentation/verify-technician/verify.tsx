"use client"

import Image from "next/image"
import { useRouter } from "next/navigation"
import { technicians } from "@/data/mock/technicians"
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

export const Verify = ({ id }: { id: number }) => {
  const technician = technicians.find((t) => t.id === id)
  const router = useRouter()

  if (!technician) {
    return <div>Technician not found</div>
  }

  const [crimeStatus, setCrimeStatus] = useState<"clean" | "crime">("clean")

  return (
    <div className="p-6 space-y-6">
      <div className="text-sm text-black/60 flex items-center gap-1">
        <Link href="/verify-technicians" className="underline">
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

        <hr className="text-colorStroke" />

        {/* Detail Box */}
        <div className="px-4 space-y-6 text-sm">
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

          <div className="flex items-center gap-2">
            <CalendarMonthIcon sx={{ fontSize: 16, color: "#9B9B9B" }} />
            <span className="text-colorTertiaryText text-[14px]">
              วันที่สมัคร
            </span>
            <span className="ml-5">12/02/69</span>
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
                  defaultValue={12392323824982}
                  disabled
                />
              </div>
            </div>

            <div className="flex flex-col gap-1 w-full">
              <p className="text-colorTertiaryText">ชื่อ - สกุล</p>
              <input
                type="text"
                className="border border-colorStroke w-full rounded-lg text-[16px] px-4 py-2 disabled:text-primaryBorder"
                defaultValue="วิชาญ จงกล"
                disabled
              />
            </div>
          </div>

          <div className="flex flex-col gap-1 w-full">
            <p className="text-colorTertiaryText">รูปถ่ายบัตรประชาชน</p>
            <div className="relative w-2/5">
              <img src="/images/ID_Card.png" alt="รูปถ่ายบัตรประชาชน" />
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
          <button className="px-20 py-1 rounded-lg bg-primary text-white cursor-pointer">
            ยืนยัน
          </button>
        </div>
      </div>
    </div>
  )
}
