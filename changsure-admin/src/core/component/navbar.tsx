"use client"
import { useState } from "react"
import { useGetAdminProfile } from "@/data/api/login.hook"
import {
  ShieldCheck,
  UserRoundCog,
  ChevronDown,
  LogOut,
  Menu
} from "lucide-react"
import Link from "next/link"
import { usePathname, useRouter } from "next/navigation"

export const DashboardLayoutUI = ({
  children
}: {
  children: React.ReactNode
}) => {
  const pathname = usePathname()
  const router = useRouter()

  const [isSidebarOpen, setIsSidebarOpen] = useState(false)
  const [isProfileOpen, setIsProfileOpen] = useState(false)
  const isManageTechActive = pathname.startsWith("/manage-technicians")
  const isVerifyTechActive = pathname.startsWith("/verify-technician")

  const { data: admin, isLoading: isLoadingAdmin } = useGetAdminProfile()

  const handleLogout = () => {
    localStorage.clear()
    router.push("/")
  }

  return (
    <div className="flex h-screen bg-gray-100 overflow-hidden">
      {/* 🔹 Overlay (Mobile) */}
      {isSidebarOpen && (
        <div
          className="fixed inset-0 bg-black/40 z-40 lg:hidden"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* 🔹 SIDEBAR */}
      <aside
        className={`
          fixed lg:static z-50 top-0 left-0 h-full w-64 bg-white border-r border-r-colorStroke flex flex-col
          transform transition-transform duration-300
          ${isSidebarOpen ? "translate-x-0" : "-translate-x-full"}
          lg:translate-x-0
        `}
      >
        {/* Logo */}
        <div className="h-16 flex items-center px-6">
          <img src={`${process.env.NEXT_PUBLIC_BASE_PATH || ""}/images/chang-sure.png`}
 className="h-8" />
        </div>

        {/* Menu */}
        <div className="flex-1 px-4 py-6 space-y-2">
          <Link href="/manage-technicians">
            <button
              onClick={() => setIsSidebarOpen(false)}
              className={`w-full flex items-center gap-3 px-4 py-2 rounded-lg cursor-pointer ${
                isManageTechActive
                  ? "bg-primaryBorderHover text-white"
                  : "hover:bg-gray-100"
              }`}
            >
              <UserRoundCog className="w-5 h-5" /> จัดการข้อมูลช่าง
            </button>
          </Link>

          <Link href="/verify-technician">
            <button
              onClick={() => setIsSidebarOpen(false)}
              className={`w-full flex items-center gap-3 my-2 px-4 py-2 rounded-lg cursor-pointer ${
                isVerifyTechActive
                  ? "bg-primaryBorderHover text-white"
                  : "hover:bg-gray-100"
              }`}
            >
              <ShieldCheck className="w-5 h-5" /> รับสมัคร/ตรวจสอบช่าง
            </button>
          </Link>

          <hr className="text-colorStroke" />

          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-2 hover:text-primary cursor-pointer px-4 py-2 hover:bg-gray-100 rounded-lg"
          >
            <LogOut className="w-5 h-5" />
            ออกจากระบบ
          </button>
        </div>
      </aside>

      {/* 🔹 RIGHT CONTENT */}
      <div className="flex-1 flex flex-col w-full">
        {/* 🔹 TOP NAVBAR */}
        <div className="h-16 bg-white flex items-center justify-between px-4 md:px-6 border-b border-colorStroke">
          {/* LEFT */}
          <div className="flex items-center gap-3 w-full md:w-1/3">
            {/* Hamburger (Tablet + Mobile) */}
            <button
              className="lg:hidden"
              onClick={() => setIsSidebarOpen(true)}
            >
              <Menu className="w-6 h-6" />
            </button>

            {/* Search */}
            {/* <input
              type="text"
              placeholder="ค้นหา..."
              className="w-full px-4 py-2 rounded-full border border-colorStroke bg-primaryBGHover focus:outline-none text-sm"
            /> */}
          </div>
          {/* RIGHT USER */}
          <div className="relative">
            {isLoadingAdmin ? (
              // Skeleton
              <div className="flex items-center gap-3 animate-pulse">
                <div className="w-10 h-10 bg-gray-300 rounded-full" />
                <div className="hidden sm:block">
                  <div className="w-24 h-3 bg-gray-300 rounded mb-1" />
                  <div className="w-16 h-2 bg-gray-200 rounded" />
                </div>
              </div>
            ) : (
              <>
                <button
                  onClick={() => setIsProfileOpen(!isProfileOpen)}
                  className="flex items-center gap-3 px-2 py-1 rounded-lg transition"
                >
                  <img
                    src={admin?.avatar_url || `${process.env.NEXT_PUBLIC_BASE_PATH || ""}/images/default-profile.png`}
                    className="w-12 h-9 md:w-10 md:h-10 rounded-full object-cover"
                  />

                  {/* ชื่อ (ซ่อนในจอเล็ก) */}
                  <div className="hidden sm:block text-left">
                    <p className=" text-[12px] md:text-[14px] font-medium leading-4">
                      {admin?.first_name} {admin?.last_name}
                    </p>
                    <p className="text-xs text-primary hidden md:block">
                      Admin
                    </p>
                  </div>
                </button>
              </>
            )}
          </div>{" "}
        </div>

        {/* 🔹 PAGE CONTENT */}
        <div className="flex-1 p-4 md:p-6 overflow-y-auto">{children}</div>
      </div>
    </div>
  )
}
