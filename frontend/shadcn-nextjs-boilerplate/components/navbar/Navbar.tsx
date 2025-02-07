"use client";

import { Button } from "@/components/ui/button";
import Image from "next/image";
import Link from "next/link";
import { Syncopate } from "next/font/google";

// Import Google Font using Next.js
const syncopate = Syncopate({ weight: "700", subsets: ["latin"] });

export default function Navbar(props: { brandText: string }) {
    return (
        <nav className="fixed left-0 right-0 z-50 flex items-center justify-between px-6 py-3 bg-white/0 backdrop-blur-md shadow-md dark:bg-black/50">
            {/* Left Side - Logo & Styled Brand Name */}
            <div className="flex items-center space-x-3">
                <Image src="/logo.png" alt="Logo" width={40} height={40} className="w-10 h-10" />
                <Link
                    href="/"
                    className={`${syncopate.className} text-[#eab71a] text-center font-bold flex items-center`}
                    style={{ fontSize: "13px" }} // Set font size to 15px
                >
                    {props.brandText}
                </Link>
            </div>

            {/* Right Side - Help Button */}
            <Button variant="outline" className="text-gray-900 dark:text-white border-gray-400 dark:border-white">
                Help
            </Button>
        </nav>
    );
}
