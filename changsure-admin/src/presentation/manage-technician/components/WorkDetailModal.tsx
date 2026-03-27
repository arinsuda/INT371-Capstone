"use client"

import Image from "next/image"
import { X } from "lucide-react"
import { useState } from "react"

type Props = {
  open: boolean
  onClose: () => void
}

const imagesMock = [
  "https://picsum.photos/300/200?1",
  "https://picsum.photos/300/200?2",
  "https://picsum.photos/300/200?3",
  "https://picsum.photos/300/200?4",
  "https://picsum.photos/300/200?5"
]

export const WorkDetailModal = ({ open, onClose }: Props) => {
  const [page, setPage] = useState(1)
  const perPage = 4

  if (!open) return null

  const start = (page - 1) * perPage
  const currentImages = imagesMock.slice(start, start + perPage)
  const totalPages = Math.ceil(imagesMock.length / perPage)

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
            <span className="text-colorTertiaryText">ชื่อเจ้าของผลงาน</span>{"  "}
            <span className="font-medium">สมชาย ใจดี</span>
          </p>

          <p>
            <span className="text-colorTertiaryText">รายละเอียดผลงาน</span>{"  "}
            ผลงานชิ้นนี้ครับ 😂 ลูกค้าชอบเป็นพิเศษ
          </p>

          <p>
            <span className="text-colorTertiaryText">ประเภทงาน</span>{"  "}
            <span className="font-medium">ทาสี</span>
          </p>

          <p>
            <span className="text-colorTertiaryText">วันที่โพสต์</span> 12/02/26
          </p>
        </div>

        {/* Images */}
        <div className="mt-5 grid grid-cols-4 gap-3">
          {currentImages.map((img, i) => (
            <div key={i} className="w-full h-35 relative">
              <Image
                src={img}
                alt="work"
                fill
                className="rounded-lg object-cover"
              />
            </div>
          ))}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-between mt-4 text-sm">
          <p className="text-[#AAAAAA]">
            จำนวนภาพทั้งหมด {imagesMock.length}/{imagesMock.length}
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
