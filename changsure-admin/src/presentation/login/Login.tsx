"use client"
import { useState } from "react"
import VisibilityOutlinedIcon from "@mui/icons-material/VisibilityOutlined"
import VisibilityOffOutlinedIcon from "@mui/icons-material/VisibilityOffOutlined"
import { useGetAdminProfile, useSendForm } from "../../data/api/login.hook"
import { useRouter } from "next/navigation"

export const LoginPage = () => {
  const [showPassword, setShowPassword] = useState(false)
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const router = useRouter()
  const { mutate, isPending, error } = useSendForm({
    onSuccess: (res: any) => {
      console.log("login success", res)

      const payload = res?.data

      if (!payload) {
        console.error("Invalid response structure")
        return
      }

      localStorage.setItem("token", payload.access_token)
      localStorage.setItem("adminId", String(payload.user.id))

      router.replace("/manage-technicians")
    },
    onError: (err: Error) => {
      console.log("login error", err)
    }
  })

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault()

    mutate({
      email,
      password
    })
  }

  return (
    <div className="max-h-screen flex">
      {/* LEFT SIDE */}
      <div className="hidden md:block md:w-3/5">
        <img
          src="/images/login.png"
          alt="login"
          className="h-full w-full object-cover"
        />
      </div>

      {/* RIGHT SIDE */}
      <div className="w-full md:w-1/2 flex items-center justify-center bg-gray-50">
        <div className="w-full max-w-md">
          <img src="/images/chang-sure.png" className="w-52" />

          <div className="pt-6">
            <h2 className="text-[36px] font-semibold mb-2">
              ลงชื่อเข้าสู่ระบบ
            </h2>
            <p className="text-colorTertiaryText text-[18px] mb-6">
              กรุณากรอกชื่อผู้ใช้และรหัสผ่าน
            </p>
          </div>

          <form className="space-y-4" onSubmit={handleLogin}>
            {/* Email */}
            <div>
              <label className="text-[16px] text-colorTertiaryText">
                อีเมล
              </label>
              <input
                type="text"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full mt-1 px-4 py-2 border border-colorStroke rounded-lg focus:outline-none focus:ring-2 focus:ring-primaryBorderHover"
              />
            </div>

            {/* Password */}
            <div>
              <label className="text-[16px] text-colorTertiaryText">
                รหัสผ่าน
              </label>

              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full mt-1 px-4 py-2 pr-12 border border-colorStroke rounded-lg focus:outline-none focus:ring-2 focus:ring-primaryBorderHover"
                />

                {/* Toggle Button */}
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500"
                >
                  {showPassword ? (
                    <VisibilityOutlinedIcon fontSize="small" />
                  ) : (
                    <VisibilityOffOutlinedIcon fontSize="small" />
                  )}
                </button>
              </div>
            </div>

            {/* Button */}
            <button
              type="submit"
              disabled={isPending}
              className="w-full py-2 mt-4 bg-primary hover:bg-primaryHover text-white rounded-xl font-medium transition cursor-pointer"
            >
              {isPending ? "กำลังเข้าสู่ระบบ..." : "เข้าสู่ระบบ"}
            </button>
            {error && (
              <p className="text-red-500 text-sm">เข้าสู่ระบบไม่สำเร็จ</p>
            )}
          </form>
        </div>
      </div>
    </div>
  )
}
