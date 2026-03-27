import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",  
  turbopack: {},
  images: {
    domains: ["i.pravatar.cc", "picsum.photos"],
  },
}

export default nextConfig;
