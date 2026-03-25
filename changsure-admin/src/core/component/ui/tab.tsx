"use client"
import { motion } from "framer-motion"
export const Tab = ({
  id,
  activeTab,
  setActiveTab,
  tab,
  ref
}: {
  id: string | number
  activeTab: string | number
  setActiveTab: Function
  tab: string
  ref?: React.Ref<HTMLButtonElement>
}) => {
  return (
    <button
      key={id}
      className={`p-2 md:p-4 w-fit relative flex items-center justify-center whitespace-nowrap text-[12px] md:text-[16px] cursor-pointer border-b border-[#EBEBEB] ${
        activeTab === id ? "text-primary font-bold " : "text-[#000000]"
      }`}
      onClick={() => setActiveTab(id)}
      ref={ref}
    >
      {tab}
      {activeTab === id && (
        <motion.div
          className="absolute bottom-0 w-full h-0.75 bg-primary z-1 "
          layoutId="underline"
        />
      )}
    </button>
  )
}
