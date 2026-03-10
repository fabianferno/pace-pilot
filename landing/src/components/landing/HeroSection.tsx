import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Mic, ArrowRight, Play, Star, Headphones } from "lucide-react";
import ShinyText from "@/components/react-bits/ShinyText";

export function HeroSection() {
  return (
    <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-[#AAFF00]/5 via-transparent to-transparent" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-[#AAFF00]/10 rounded-full blur-3xl" />

      <div className="max-w-7xl mx-auto relative">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Hero text - left */}
          <div className="order-1 lg:order-1 text-center lg:text-left">
            <Badge className="mb-6 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20 hover:bg-[#AAFF00]/20">
              <Mic className="w-3 h-3 mr-1" />
              Voice-First AI Coaching
            </Badge>

            <div className="font-coolvetica text-4xl md:text-6xl lg:text-7xl font-light tracking-tight mb-6">
              <div className="-my-2">
                Your Personal
              </div>
              <ShinyText
                text="Running Coach"
                color="#AAFF00"
                shineColor="#ffffff"
                speed={2.5}
                spread={120}
                className="font-coolvetica block leading-[1.15]"
              />
              <div className="-my-2">
                On Every Run
              </div>
            </div>

            <p className="text-lg sm:text-xl text-gray-400 mb-8 max-w-xl lg:max-w-none">
              Stop running alone. PacePilot is an AI coach that speaks to you in real-time,
              adapts to your biometrics, and builds a training relationship that gets you to your goals.
            </p>

            <div className="flex flex-col sm:flex-row items-center lg:items-start justify-center lg:justify-start gap-4 mb-12">
              <Button size="lg" className="bg-[#AAFF00] text-black hover:bg-[#88CC00] text-base font-semibold px-8 animate-pulse-glow">
                Start Your First Coached Run
                <ArrowRight className="w-4 h-4 ml-2" />
              </Button>
              <Button size="lg" variant="outline" className="border-white/20 hover:bg-white/5 text-base">
                <Play className="w-4 h-4 mr-2" />
                Watch Demo
              </Button>
            </div>

            <div className="flex items-center justify-center lg:justify-start gap-8 text-sm text-gray-500">
              <div className="flex items-center gap-2">
                <div className="flex -space-x-2">
                  {[1, 2, 3, 4].map((i) => (
                    <div key={i} className="w-8 h-8 rounded-full bg-gradient-to-br from-gray-700 to-gray-800 border-2 border-black" />
                  ))}
                </div>
                <span>10,000+ runners</span>
              </div>
              <div className="flex items-center gap-1">
                {[1, 2, 3, 4, 5].map((i) => (
                  <Star key={i} className="w-4 h-4 fill-[#AAFF00] text-[#AAFF00]" />
                ))}
                <span className="ml-1">4.9/5</span>
              </div>
            </div>
          </div>

          {/* iPhone mockup - right */}
          <div className="order-2 lg:order-2 flex justify-center lg:justify-end">
            <div className="relative">
              <div className="absolute -inset-4 bg-[#AAFF00]/10 rounded-[4rem] blur-2xl" />
              <div className="relative w-[280px] sm:w-[320px] mx-auto">
                {/* iPhone frame */}
                <div className="relative bg-zinc-900 rounded-[3.5rem] p-2 sm:p-2.5 border border-zinc-700 shadow-2xl shadow-black/50">
                  {/* Dynamic Island */}
                  <div className="absolute top-6 left-1/2 -translate-x-1/2 w-24 h-7 bg-black rounded-full z-20" />
                  {/* Screen */}
                  <div className="aspect-[9/19.5] rounded-[3rem] overflow-hidden bg-gradient-to-br from-zinc-800/50 to-zinc-900/50 relative">
                    <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-20" />
                    <div className="absolute inset-0 flex flex-col items-center justify-center p-6 text-center z-10">
                      <div className="w-16 h-16 rounded-full bg-[#AAFF00]/20 flex items-center justify-center mx-auto mb-4 animate-float">
                        <Headphones className="w-8 h-8 text-[#AAFF00]" />
                      </div>
                      <p className="text-gray-400 text-xs sm:text-sm leading-relaxed">
                        &quot;You&apos;re at 5:12 pace — right on target for your tempo. Let&apos;s hold this for 2 more kilometers.&quot;
                      </p>
                      <div className="mt-4 flex flex-col items-center gap-2">
                        <div className="flex items-center gap-2 text-[#AAFF00]">
                          <div className="w-2 h-2 rounded-full bg-[#AAFF00] animate-pulse" />
                          <span className="text-xs">Coach is listening...</span>
                        </div>
                        <div className="flex items-end gap-1 h-5 mt-4">
                          {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map((i) => (
                            <div
                              key={i}
                              className="w-1.5 h-5 rounded-full bg-[#AAFF00] animate-sound-wave"
                              style={{ animationDelay: `${i * 0.06}s` }}
                            />
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
