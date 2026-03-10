import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ChevronRight } from "lucide-react";
import ShinyText from "@/components/react-bits/ShinyText";

const plans = [
  {
    name: "Free",
    price: "$0",
    period: "forever",
    description: "Get started with basic coaching",
    features: [
      "Voice coaching on runs",
      "Basic training plan",
      "Run tracking & history",
      "Community access",
    ],
    cta: "Start Free",
    highlighted: false,
    annualSavings: null,
  },
  {
    name: "Weekly",
    price: "$4.99",
    period: "/week",
    description: "Try before you commit",
    features: [
      "Everything in Free",
      "Adaptive training plans",
      "Real-time biometric coaching",
      "Apple Watch integration",
      "Calendar sync",
      "Strava integration",
    ],
    cta: "Start Weekly",
    highlighted: false,
    annualSavings: null,
  },
  {
    name: "Monthly",
    price: "$9.99",
    period: "/month",
    description: "Best value — save with annual",
    features: [
      "Everything in Weekly",
      "Priority support",
      "Advanced analytics",
      "Race preparation tools",
    ],
    cta: "Start Monthly",
    highlighted: true,
    annualSavings: "Save 20% with annual",
  },
];

export function PricingSection() {
  return (
    <section id="pricing" className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
            Pricing
          </Badge>
          <h2 className="font-coolvetica text-3xl  md:text-5xl font-light mb-4">
            Invest in Your <ShinyText text="Running Journey" color="#AAFF00" shineColor="#ffffff" speed={2.5} spread={120} />
          </h2>
          <p className="text-zinc-400 max-w-2xl mx-auto">
            Start free, upgrade when you&apos;re ready. Cancel anytime.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {plans.map((plan, index) => (
            <Card
              key={index}
              className={`relative flex flex-col h-full ${plan.highlighted
                ? "bg-gradient-to-b from-[#AAFF00]/10 to-zinc-900 border-[#AAFF00]/30 glow-border"
                : "bg-zinc-900/50 border-white/5"
                }`}
            >
              {plan.highlighted && (
                <div className="absolute top-4 left-1/2 -translate-x-1/2">
                  <Badge className="bg-[#AAFF00] text-black font-semibold">Best Value</Badge>
                </div>
              )}
              <CardContent className="p-6 flex flex-col flex-1">
                <h3 className="text-xl font-semibold mb-2">{plan.name}</h3>
                <div className="flex items-baseline gap-1 mb-2">
                  <span className="text-4xl font-bold">{plan.price}</span>
                  <span className="text-zinc-400">{plan.period}</span>
                </div>
                {plan.annualSavings && (
                  <p className="text-[#AAFF00] text-sm font-medium mb-2">{plan.annualSavings}</p>
                )}
                <p className="text-zinc-400 text-sm mb-6">{plan.description}</p>

                <ul className="space-y-3 mb-6">
                  {plan.features.map((feature, i) => (
                    <li key={i} className="flex items-center gap-2 text-sm">
                      <ChevronRight className="w-4 h-4 text-[#AAFF00]" />
                      <span className="text-zinc-300">{feature}</span>
                    </li>
                  ))}
                </ul>

                <Button
                  className={`w-full mt-auto ${plan.highlighted
                    ? "bg-[#AAFF00] text-black hover:bg-[#88CC00]"
                    : "bg-white/10 hover:bg-white/20"
                    }`}
                >
                  {plan.cta}
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
}
