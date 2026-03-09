import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "https://pacepilot.app"),
  title: {
    default: "PacePilot - Your AI Running Coach",
    template: "%s | PacePilot",
  },
  description:
    "A voice-first AI running coach that rides alongside you on every run. Real-time coaching, personalized training plans, and a coach that knows you.",
  keywords: [
    "running",
    "AI coach",
    "training plan",
    "marathon",
    "5k",
    "voice coaching",
    "fitness",
    "running app",
    "Apple Watch",
  ],
  authors: [{ name: "PacePilot" }],
  creator: "PacePilot",
  robots: {
    index: true,
    follow: true,
  },
  openGraph: {
    title: "PacePilot - Your AI Running Coach",
    description:
      "A voice-first AI running coach that rides alongside you on every run. Real-time coaching, personalized training plans, and a coach that knows you.",
    type: "website",
    siteName: "PacePilot",
  },
  twitter: {
    card: "summary_large_image",
    title: "PacePilot - Your AI Running Coach",
    description:
      "A voice-first AI running coach that rides alongside you on every run.",
  },
  alternates: {
    canonical: "/",
  },
  category: "fitness",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  );
}
