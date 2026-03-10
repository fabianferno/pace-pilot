import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { ChevronRight } from "lucide-react";

export function SolutionSection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 relative">
      <div className="absolute inset-0 bg-gradient-to-r from-[#AAFF00]/5 via-transparent to-[#AAFF00]/5" />

      <div className="max-w-7xl mx-auto relative">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          <div>
            <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
              The Solution
            </Badge>
            <h2 className="font-coolvetica text-3xl sm:text-4xl font-light mb-6">
              Meet PacePilot: Your Coach That&apos;s <span className="gradient-text">Always With You</span>
            </h2>
            <p className="text-zinc-400 mb-8">
              PacePilot is a voice-first AI running coach powered by Google Gemini. It doesn&apos;t just
              give you a plan — it rides alongside you on every run, watching your biometrics,
              adapting in real-time, and building a coaching relationship that gets smarter every mile.
            </p>

            <div className="space-y-4">
              {[
                "Real-time voice coaching during your runs",
                "Adapts to your heart rate, pace, and how you feel",
                "Builds a personalized plan from a single conversation",
                "Celebrates your wins and pushes through your walls",
              ].map((item, index) => (
                <div key={index} className="flex items-center gap-3">
                  <div className="w-6 h-6 rounded-full bg-[#AAFF00] flex items-center justify-center flex-shrink-0">
                    <ChevronRight className="w-4 h-4 text-black" />
                  </div>
                  <span className="text-zinc-300">{item}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="relative max-w-md mx-auto ">
            <div className="absolute -inset-4 bg-[#AAFF00]/10 rounded-3xl blur-2xl" />
            <Card className="bg-zinc-900 border-white/10 relative glow-border">
              <CardContent className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <img
                    src="/logo/logo.png"
                    alt="PacePilot"
                    className="w-10 h-10 rounded-full object-contain bg-[#AAFF00]/20 p-1"
                  />
                  <div>
                    <p className="font-semibold">PacePilot</p>
                    <p className="text-xs text-zinc-400">Active Run • 4.2 km</p>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="bg-black/50 rounded-xl p-4">
                    <p className="text-sm text-zinc-300 italic">
                      &quot;Great first kilometer! Your heart rate is sitting at 142 — perfect Zone 2.
                      This is exactly where we want to be for your easy run. How are your legs feeling?&quot;
                    </p>
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    <div className="bg-black/50 rounded-lg p-3 text-center">
                      <p className="text-2xl font-bold text-[#AAFF00]">5:24</p>
                      <p className="text-xs text-zinc-400">Pace /km</p>
                    </div>
                    <div className="bg-black/50 rounded-lg p-3 text-center">
                      <p className="text-2xl font-bold">142</p>
                      <p className="text-xs text-zinc-400">Heart Rate</p>
                    </div>
                    <div className="bg-black/50 rounded-lg p-3 text-center">
                      <p className="text-2xl font-bold">4.2</p>
                      <p className="text-xs text-zinc-400">Distance km</p>
                    </div>
                  </div>

                  <div className="flex items-center justify-center">
                    <div className="flex items-center gap-2 text-[#AAFF00]">
                      <div className="w-2 h-2 rounded-full bg-[#AAFF00] animate-pulse" />
                      <span className="text-sm">Coach is listening...</span>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </section>
  );
}
