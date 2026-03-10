import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Star } from "lucide-react";
import ShinyText from "@/components/react-bits/ShinyText";

const testimonials = [
  {
    quote: "I've tried every running app out there. PacePilot is the first one that actually feels like having a coach. It told me to slow down on my easy runs and I finally stopped getting injured.",
    name: "Sarah Chen",
    role: "Marathon Runner",
    avatar: "SC",
    result: "PR'd by 12 minutes",
  },
  {
    quote: "The voice coaching during intervals is a game changer. I used to always go out too fast. Now my coach keeps me honest and I'm hitting splits I never thought possible.",
    name: "Marcus Johnson",
    role: "5K Specialist",
    avatar: "MJ",
    result: "Sub-18 5K achieved",
  },
  {
    quote: "As a busy mom, I needed a plan that could flex. When I missed runs, PacePilot just adjusted. No guilt, no falling behind. Just smart coaching.",
    name: "Emily Rodriguez",
    role: "Half Marathon Runner",
    avatar: "ER",
    result: "First half marathon finished",
  },
];

export function TestimonialsSection() {
  return (
    <section id="testimonials" className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-black to-zinc-950">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
            Testimonials
          </Badge>
          <h2 className="font-coolvetica text-3xl sm:text-4xl font-light mb-4">
            Runners Who Found Their <ShinyText text="Breakthrough" color="#AAFF00" shineColor="#ffffff" speed={2.5} spread={120} />
          </h2>
          <p className="text-zinc-400 max-w-2xl mx-auto">
            Join thousands of runners who&apos;ve transformed their training with PacePilot.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {testimonials.map((testimonial, index) => (
            <Card key={index} className="bg-zinc-900/50 border-white/5 hover:border-[#AAFF00]/20 transition-colors">
              <CardContent className="p-6">
                <div className="flex items-center gap-1 mb-4">
                  {[1, 2, 3, 4, 5].map((i) => (
                    <Star key={i} className="w-4 h-4 fill-[#AAFF00] text-[#AAFF00]" />
                  ))}
                </div>
                <p className="text-zinc-300 mb-6 italic">&quot;{testimonial.quote}&quot;</p>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Avatar className="w-10 h-10 bg-[#AAFF00]/20">
                      <AvatarFallback className="bg-[#AAFF00]/20 text-[#AAFF00]">{testimonial.avatar}</AvatarFallback>
                    </Avatar>
                    <div>
                      <p className="font-semibold text-sm">{testimonial.name}</p>
                      <p className="text-xs text-zinc-400">{testimonial.role}</p>
                    </div>
                  </div>
                  <Badge className="bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20 text-xs">
                    {testimonial.result}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="mt-12 flex flex-wrap items-center justify-center gap-8 opacity-50">
          <p className="text-sm text-zinc-400">As featured in:</p>
          <div className="flex items-center gap-8">
            {["Runner's World", "Strava", "Apple Fitness+", "Men's Health"].map((brand) => (
              <span key={brand} className="text-zinc-500 font-semibold">{brand}</span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
