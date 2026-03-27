import type { Metadata } from "next"
import { Noto_Sans_Thai } from "next/font/google"
import "../core/css/globals.css"
import { ClientProviders } from "@/core/providers/client-providers"

const noto = Noto_Sans_Thai({
  subsets: ["thai"],
  weight: ["400", "500", "600", "700"]
})

export const metadata: Metadata = {
  title: "ChangSure",
  icons: {
    icon: `${process.env.NEXT_PUBLIC_BASE_PATH || ""}/images/logo-changsure.png`
  }
}

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <body className={noto.className}>
        {" "}
        <ClientProviders>{children}</ClientProviders>
      </body>
    </html>
  )
}
