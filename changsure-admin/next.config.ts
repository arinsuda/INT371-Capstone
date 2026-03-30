import type { NextConfig } from "next"

const nextConfig: NextConfig = {
  basePath: "/capstone25/cp25ssa1",
  trailingSlash: true,
  output: "standalone",
  images: {
    domains: ["i.pravatar.cc", "picsum.photos", "bscit.sit.kmutt.ac.th"]
  },
}

export default nextConfig
