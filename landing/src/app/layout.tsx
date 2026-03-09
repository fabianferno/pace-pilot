import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "PacePilot - Your AI Running Coach",
  description: "A voice-first AI running coach that rides alongside you on every run. Real-time coaching, personalized training plans, and a coach that knows you.",
  keywords: ["running", "AI coach", "training plan", "marathon", "5k", "voice coaching", "fitness"],
  openGraph: {
    title: "PacePilot - Your AI Running Coach",
    description: "A voice-first AI running coach that rides alongside you on every run.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.variable} antialiased`}>
        {children}
      </body>
    </html>
  );
}
