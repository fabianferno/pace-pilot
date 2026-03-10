import { Badge } from "@/components/ui/badge";
import { Mic, Calendar, Headphones, TrendingUp } from "lucide-react";
import ShinyText from "@/components/react-bits/ShinyText";

const steps = [
  {
    number: "01",
    title: "Have a Conversation",
    description: "No forms. No quizzes. Just talk to your coach about your goals, experience, and schedule. PacePilot builds your plan from a natural conversation.",
    icon: Mic,
  },
  {
    number: "02",
    title: "Get Your Plan",
    description: "Receive a periodized training plan tailored to your goal race, current fitness, and available time. Synced to your calendar automatically.",
    icon: Calendar,
  },
  {
    number: "03",
    title: "Run With Your Coach",
    description: "Hit start and your coach joins you. Real-time voice guidance based on your biometrics, the workout targets, and how you're feeling.",
    icon: Headphones,
  },
  {
    number: "04",
    title: "Get Faster, Together",
    description: "After every run, your coach debriefs you. Your plan adapts. Your community cheers. You get closer to your goal.",
    icon: TrendingUp,
  },
];

export function HowItWorksSection() {
  return (
    <section id="how-it-works" className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
            How It Works
          </Badge>
          <h2 className="font-coolvetica text-3xl sm:text-4xl font-light mb-4">
            From Download to <ShinyText text="Personal Best" color="#AAFF00" shineColor="#ffffff" speed={2.5} spread={120} />
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto">
            Getting started takes less than 5 minutes. Your first coached run? That&apos;s today.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {steps.map((step, index) => (
            <div key={index} className="relative">
              {index < steps.length - 1 && (
                <div className="hidden lg:block absolute top-12 left-full w-full h-px bg-gradient-to-r from-[#AAFF00]/50 to-transparent z-0" />
              )}
              <div className="relative z-10">
                <div className="text-5xl font-bold text-[#AAFF00]/20 mb-4">{step.number}</div>
                <div className="w-12 h-12 rounded-xl bg-[#AAFF00] flex items-center justify-center mb-4">
                  <step.icon className="w-6 h-6 text-black" />
                </div>
                <h3 className="text-xl font-semibold mb-2">{step.title}</h3>
                <p className="text-gray-400 text-sm">{step.description}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
