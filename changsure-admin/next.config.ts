import type { NextConfig } from "next"

const nextConfig: NextConfig = {
  /* config options here */
  turbopack: {},
  images: {
    domains: ["i.pravatar.cc", "picsum.photos", "bscit.sit.kmutt.ac.th"]
  }
}

export default nextConfig
