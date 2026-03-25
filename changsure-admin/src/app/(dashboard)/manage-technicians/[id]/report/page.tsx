import { ReportTech } from "@/presentation/manage-technician/report-tech"

export default async function Page({
  params
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  return <ReportTech id={Number(id)} />
}
