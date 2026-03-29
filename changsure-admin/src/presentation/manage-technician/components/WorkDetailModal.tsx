"use client"

import Image from "next/image"
import { X } from "lucide-react"
import { useState } from "react"
import {
  useGetTechnicianById,
  useGetTechnicianPostById
} from "@/data/api/technicians.hook"

type Props = {
  open: boolean
  onClose: () => void
  postId: number
  technicianId: number
}

const imagesMock = [
  "https://picsum.photos/300/200?1",
  "https://picsum.photos/300/200?2",
  "https://picsum.photos/300/200?3",
  "https://picsum.photos/300/200?4",
  "https://picsum.photos/300/200?5"
]

export const WorkDetailModal = ({
  open,
  onClose,
  postId,
  technicianId
}: Props) => {
  const [page, setPage] = useState(1)
  const perPage = 4
  const { data, isLoading } = useGetTechnicianPostById(technicianId, postId)
  const { data: technician } = useGetTechnicianById(technicianId)

  if (!open) return null

  const images = Array.isArray(data?.images) ? data.images : []

  const start = (page - 1) * perPage
  const currentImages = images.slice(start, start + perPage)
  const totalPages = Math.ceil(images.length / perPage)

  const formatDateTime = (timestamp: number) => {
    const date = new Date(timestamp * 1000)

    const day = String(date.getDate()).padStart(2, "0")
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const year = date.getFullYear()

    return `${day}/${month}/${year}`
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Overlay */}
      <div
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="relative bg-white w-225 rounded-2xl shadow-xl p-6 z-50">
        {/* Close */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 text-black/40 hover:text-black cursor-pointer"
        >
          <X />
        </button>

        {/* Header */}
        <h2 className="text-xl font-semibold mb-4">รายละเอียดผลงาน</h2>

        {/* Content */}
        <div className="space-y-3 text-sm">
          <p>
            <span className="text-colorTertiaryText">ชื่อเจ้าของผลงาน</span>
            {"  "}
            <span className="">
              {technician?.firstname} {technician?.lastname}
            </span>
          </p>

          <p>
            <span className="text-colorTertiaryText">รายละเอียดผลงาน</span>
            {"  "}
            {data?.description ? (
              <span className="">{data.description}</span>
            ) : (
              <span className=" text-gray-500">ไม่มีรายละเอียด</span>
            )}
          </p>

          <p>
            <span className="text-colorTertiaryText">ประเภทงาน</span>
            {"  "}
            <span className="">{data?.category_name}</span>
          </p>

          <p>
            <span className="text-colorTertiaryText">วันที่โพสต์</span> {"  "}
            <span className="">
              {data?.created_at
                ? formatDateTime(data.created_at)
                : "ไม่มีวันที่"}
            </span>
          </p>
        </div>

        {/* Images */}
        <div className="mt-5 grid grid-cols-4 gap-3">
          {currentImages.length > 0 ? (
            currentImages.map((img) => {
              const imageUrl =
                typeof img.image_url === "string" && img.image_url.trim() !== ""
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

        {/* Footer */}
        <div className="flex items-center justify-between mt-4 text-sm">
          <p className="text-[#AAAAAA]">
            จำนวนภาพทั้งหมด {currentImages.length}/{images.length}
          </p>

          {/* Pagination */}
          <div className="flex items-center gap-2">
            <button
              disabled={page === 1}
              onClick={() => setPage(page - 1)}
              className="px-2 py-1 text-black disabled:opacity-30"
            >
              &lt;
            </button>

            {Array.from({ length: totalPages }).map((_, i) => (
              <button
                key={i}
                onClick={() => setPage(i + 1)}
                className={`w-7 h-7 rounded-md text-xs ${
                  page === i + 1
                    ? "text-primary border border-primary"
                    : "text-black"
                }`}
              >
                {i + 1}
              </button>
            ))}

            <button
              disabled={page === totalPages}
              onClick={() => setPage(page + 1)}
              className="px-2 py-1 text-black disabled:opacity-30"
            >
              &gt;
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
