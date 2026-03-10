import MagicBento from "@/components/react-bits/MagicBento";
import type { BentoCardProps } from "@/components/react-bits/MagicBento";
import { Badge } from "@/components/ui/badge";
import ShinyText from "@/components/react-bits/ShinyText";

const features: BentoCardProps[] = [
  {
    color: "#0a0a0a",
    title: "Voice-First Coaching",
    description: "No more glancing at your watch. Your coach speaks to you naturally, just like a real running partner.",
    label: "Stay focused on your run, not your screen",
    image: "/images/features/feature-voice-coaching.png",
  },
  {
    color: "#0a0a0a",
    title: "Real-Time Biometrics",
    description: "PacePilot watches your heart rate, pace, and cadence — adjusting coaching based on how your body is actually responding.",
    label: "Train smarter, recover faster",
    image: "/images/features/feature-biometrics.png",
  },
  {
    color: "#0a0a0a",
    title: "Adaptive Training Plans",
    description: "Plans that flex around your life. Missed a run? Feeling tired? Your coach rebalances automatically.",
    label: "A plan that works with your schedule",
    image: "/images/features/feature-training-plans.png",
  },
  {
    color: "#0a0a0a",
    title: "Apple Watch Integration",
    description: "Seamless sync with your Apple Watch for accurate biometrics and haptic feedback during intervals.",
    label: "Your wrist becomes your coach",
    image: "/images/features/feature-apple-watch.png",
  },
  {
    color: "#0a0a0a",
    title: "Pace-Based Communities",
    description: "Get matched with runners at your level. See their runs, compete on leaderboards, find your tribe.",
    label: "Never run alone again",
    image: "/images/features/feature-communities.png",
  },
  {
    color: "#0a0a0a",
    title: "Race Discovery",
    description: "Find local races that match your goals. Your coach helps you peak at the right time.",
    label: "Cross that finish line prepared",
    image: "/images/features/feature-race-discovery.png",
  },
];

export function FeaturesSection() {
  return (
    <section id="features" className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-zinc-950 to-black">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
            Features
          </Badge>
          <h2 className="font-coolvetica text-3xl sm:text-4xl font-light mb-4">
            Everything You Need to <ShinyText text="Run Your Best" color="#AAFF00" shineColor="#ffffff" speed={2.5} spread={120} />
          </h2>
          <p className="text-zinc-400 max-w-2xl mx-auto">
            PacePilot combines cutting-edge AI with deep running expertise to deliver
            coaching that was previously only available to elite athletes.
          </p>
        </div>

        <div className="flex justify-center w-full">
          <MagicBento
            cards={features}
            fullWidth
            textAutoHide={true}
            // enableStars
            // enableSpotlight
            enableBorderGlow={true}
            enableTilt={false}
            enableMagnetism={false}
            clickEffect
            spotlightRadius={400}
            particleCount={0}
            glowColor="170, 255, 0"
            disableAnimations={false}
          />
        </div>
      </div>
    </section>
  );
}
