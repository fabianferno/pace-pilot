import { Button } from "@/components/ui/button";
import { ArrowRight, Smartphone, Zap, Heart } from "lucide-react";
import ShinyText from "../react-bits/ShinyText";

export function CTASection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-r from-[#AAFF00]/10 via-[#AAFF00]/5 to-[#AAFF00]/10" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-[#AAFF00]/10 rounded-full blur-3xl" />

      <div className="max-w-4xl mx-auto text-center relative">
        <h2 className="font-coolvetica text-3xl  md:text-7xl font-light mb-6">
          Ready to Run With a Coach Who <ShinyText text="Actually Knows You?" color="#AAFF00" shineColor="#ffffff" speed={2.5} spread={120} />
        </h2>
        <p className="text-xl text-zinc-400 mb-8 max-w-2xl mx-auto">
          Your first coached run is waiting. No credit card required.
          Just you, your shoes, and a coach that&apos;s about to change everything.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-8">
          <Button size="lg" className="bg-[#AAFF00] text-black hover:bg-[#88CC00] text-base font-semibold px-8 animate-pulse-glow">
            Start Your Free Coached Run
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>

        <div className="flex items-center justify-center gap-6 text-sm text-zinc-400">
          <div className="flex items-center gap-2">
            <Smartphone className="w-4 h-4" />
            <span>iOS & Apple Watch</span>
          </div>
          <div className="flex items-center gap-2">
            <Zap className="w-4 h-4" />
            <span>Setup in 5 minutes</span>
          </div>
          <div className="flex items-center gap-2">
            <Heart className="w-4 h-4" />
            <span>No credit card</span>
          </div>
        </div>
      </div>
    </section>
  );
}
