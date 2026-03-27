import { Verify } from "@/presentation/verify-technician/verify"

export default async function Page({
  params
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params

  return <Verify id={Number(id)} />
}
