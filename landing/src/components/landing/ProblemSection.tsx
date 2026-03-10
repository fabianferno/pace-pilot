import { Card, CardContent } from "@/components/ui/card";
import { Timer, Target, TrendingUp } from "lucide-react";
import ShinyText from "../react-bits/ShinyText";


const problems = [
  {
    icon: Timer,
    title: "Training plans that don't adapt",
    description: "Generic plans can't see when you're tired, sick, or crushing it. They just keep pushing the same schedule.",
  },
  {
    icon: Target,
    title: "No feedback when it matters",
    description: "You check your watch after the run, but by then it's too late. The interval was too fast. The easy run wasn't easy.",
  },
  {
    icon: TrendingUp,
    title: "Motivation that fades",
    description: "Week 1 is exciting. Week 6? You're questioning everything. There's no one to tell you you're on track.",
  },
];

export function ProblemSection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-black to-zinc-950">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="font-coolvetica text-3xl sm:text-4xl font-light mb-4">
            <ShinyText text="Running Alone" color="#bbbbbb" shineColor="#ffffff" speed={2} spread={120} />
            <span className="text-zinc-500"> is Holding You Back</span>
          </h2>
          <p className="text-zinc-400 max-w-2xl mx-auto">
            You&apos;ve downloaded the apps. You&apos;ve followed the plans. But something&apos;s missing —
            a coach who actually knows you, sees your data, and speaks to you when you need it.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {problems.map((problem, index) => (
            <Card key={index} className="bg-zinc-900/50 border-white/5 hover:border-[#AAFF00]/20 transition-colors">
              <CardContent className="p-6">
                <div className="w-12 h-12 rounded-xl bg-[#AAFF00]/10 flex items-center justify-center mb-4">
                  <problem.icon className="w-6 h-6 text-[#AAFF00]" />
                </div>
                <h3 className="text-lg font-semibold mb-2">{problem.title}</h3>
                <p className="text-zinc-400 text-sm">{problem.description}</p>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="mt-12 text-center">
          <p className="text-xl text-zinc-300">
            What if your coach could <span className="text-[#AAFF00]">see your heart rate spike</span> and
            tell you to ease up — <span className="text-[#AAFF00]">before</span> you blow up?
          </p>
        </div>
      </div>
    </section>
  );
}
