import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Ogul — Facial Recovery Tracking",
  description:
    "Track post-surgical facial recovery with guided 3D scanning and longitudinal analytics.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-slate-50 text-slate-900 antialiased">
        {children}
      </body>
    </html>
  );
}
