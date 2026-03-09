"use client";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Mic,
  Heart,
  Activity,
  Calendar,
  Users,
  Trophy,
  Zap,
  Watch,
  ChevronRight,
  Star,
  Play,
  ArrowRight,
  Timer,
  Target,
  TrendingUp,
  Headphones,
  MapPin,
  Smartphone,
} from "lucide-react";

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-black text-white">
      <Header />
      <HeroSection />
      <ProblemSection />
      <SolutionSection />
      <FeaturesSection />
      <HowItWorksSection />
      <TestimonialsSection />
      <PricingSection />
      <CTASection />
      <Footer />
    </div>
  );
}

function Header() {
  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-lg border-b border-white/10">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-[#AAFF00] flex items-center justify-center">
              <Activity className="w-5 h-5 text-black" />
            </div>
            <span className="font-bold text-lg">PacePilot</span>
          </div>
          <nav className="hidden md:flex items-center gap-8">
            <a href="#features" className="text-sm text-gray-400 hover:text-white transition-colors">Features</a>
            <a href="#how-it-works" className="text-sm text-gray-400 hover:text-white transition-colors">How It Works</a>
            <a href="#testimonials" className="text-sm text-gray-400 hover:text-white transition-colors">Testimonials</a>
            <a href="#pricing" className="text-sm text-gray-400 hover:text-white transition-colors">Pricing</a>
          </nav>
          <div className="flex items-center gap-4">
            <Button variant="ghost" className="text-sm hidden sm:inline-flex">
              Log In
            </Button>
            <Button className="bg-[#AAFF00] text-black hover:bg-[#88CC00] text-sm font-semibold">
              Start Training Free
            </Button>
          </div>
        </div>
      </div>
    </header>
  );
}

function HeroSection() {
  return (
    <section className="pt-32 pb-20 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-b from-[#AAFF00]/5 via-transparent to-transparent" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-[#AAFF00]/10 rounded-full blur-3xl" />
      
      <div className="max-w-7xl mx-auto relative">
        <div className="text-center max-w-4xl mx-auto">
          <Badge className="mb-6 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20 hover:bg-[#AAFF00]/20">
            <Mic className="w-3 h-3 mr-1" />
            Voice-First AI Coaching
          </Badge>
          
          <h1 className="text-4xl sm:text-5xl md:text-7xl font-bold tracking-tight mb-6">
            Your Personal
            <span className="gradient-text block">Running Coach</span>
            On Every Run
          </h1>
          
          <p className="text-lg sm:text-xl text-gray-400 mb-8 max-w-2xl mx-auto">
            Stop running alone. PacePilot is an AI coach that speaks to you in real-time, 
            adapts to your biometrics, and builds a training relationship that gets you to your goals.
          </p>
          
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-12">
            <Button size="lg" className="bg-[#AAFF00] text-black hover:bg-[#88CC00] text-base font-semibold px-8 animate-pulse-glow">
              Start Your First Coached Run
              <ArrowRight className="w-4 h-4 ml-2" />
            </Button>
            <Button size="lg" variant="outline" className="border-white/20 hover:bg-white/5 text-base">
              <Play className="w-4 h-4 mr-2" />
              Watch Demo
            </Button>
          </div>
          
          <div className="flex items-center justify-center gap-8 text-sm text-gray-500">
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
        
        <div className="mt-16 relative">
          <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-transparent z-10" />
          <div className="bg-gradient-to-br from-gray-900 to-black rounded-2xl border border-white/10 p-4 sm:p-8 glow-border">
            <div className="aspect-video bg-gradient-to-br from-gray-800/50 to-gray-900/50 rounded-xl flex items-center justify-center relative overflow-hidden">
              <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-20" />
              <div className="text-center z-10">
                <div className="w-20 h-20 rounded-full bg-[#AAFF00]/20 flex items-center justify-center mx-auto mb-4 animate-float">
                  <Headphones className="w-10 h-10 text-[#AAFF00]" />
                </div>
                <p className="text-gray-400 text-sm">&quot;You&apos;re at 5:12 pace — right on target for your tempo. Let&apos;s hold this for 2 more kilometers.&quot;</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function ProblemSection() {
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

  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-black to-gray-950">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            Running Alone is <span className="text-gray-500">Holding You Back</span>
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto">
            You&apos;ve downloaded the apps. You&apos;ve followed the plans. But something&apos;s missing — 
            a coach who actually knows you, sees your data, and speaks to you when you need it.
          </p>
        </div>
        
        <div className="grid md:grid-cols-3 gap-6">
          {problems.map((problem, index) => (
            <Card key={index} className="bg-gray-900/50 border-white/5 hover:border-[#AAFF00]/20 transition-colors">
              <CardContent className="p-6">
                <div className="w-12 h-12 rounded-xl bg-red-500/10 flex items-center justify-center mb-4">
                  <problem.icon className="w-6 h-6 text-red-400" />
                </div>
                <h3 className="text-lg font-semibold mb-2">{problem.title}</h3>
                <p className="text-gray-400 text-sm">{problem.description}</p>
              </CardContent>
            </Card>
          ))}
        </div>
        
        <div className="mt-12 text-center">
          <p className="text-xl text-gray-300">
            What if your coach could <span className="text-[#AAFF00]">see your heart rate spike</span> and 
            tell you to ease up — <span className="text-[#AAFF00]">before</span> you blow up?
          </p>
        </div>
      </div>
    </section>
  );
}

function SolutionSection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 relative">
      <div className="absolute inset-0 bg-gradient-to-r from-[#AAFF00]/5 via-transparent to-[#AAFF00]/5" />
      
      <div className="max-w-7xl mx-auto relative">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          <div>
            <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
              The Solution
            </Badge>
            <h2 className="text-3xl sm:text-4xl font-bold mb-6">
              Meet PacePilot: Your Coach That&apos;s <span className="gradient-text">Always With You</span>
            </h2>
            <p className="text-gray-400 mb-8">
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
                  <span className="text-gray-300">{item}</span>
                </div>
              ))}
            </div>
          </div>
          
          <div className="relative">
            <div className="absolute -inset-4 bg-[#AAFF00]/10 rounded-3xl blur-2xl" />
            <Card className="bg-gray-900 border-white/10 relative glow-border">
              <CardContent className="p-6">
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-10 h-10 rounded-full bg-[#AAFF00] flex items-center justify-center">
                    <Mic className="w-5 h-5 text-black" />
                  </div>
                  <div>
                    <p className="font-semibold">PacePilot</p>
                    <p className="text-xs text-gray-400">Active Run • 4.2 km</p>
                  </div>
                </div>
                
                <div className="space-y-4">
                  <div className="bg-black/50 rounded-xl p-4">
                    <p className="text-sm text-gray-300 italic">
                      &quot;Great first kilometer! Your heart rate is sitting at 142 — perfect Zone 2. 
                      This is exactly where we want to be for your easy run. How are your legs feeling?&quot;
                    </p>
                  </div>
                  
                  <div className="grid grid-cols-3 gap-3">
                    <div className="bg-black/50 rounded-lg p-3 text-center">
                      <p className="text-2xl font-bold text-[#AAFF00]">5:24</p>
                      <p className="text-xs text-gray-400">Pace /km</p>
                    </div>
                    <div className="bg-black/50 rounded-lg p-3 text-center">
                      <p className="text-2xl font-bold">142</p>
                      <p className="text-xs text-gray-400">Heart Rate</p>
                    </div>
                    <div className="bg-black/50 rounded-lg p-3 text-center">
                      <p className="text-2xl font-bold">4.2</p>
                      <p className="text-xs text-gray-400">Distance km</p>
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

function FeaturesSection() {
  const features = [
    {
      icon: Mic,
      title: "Voice-First Coaching",
      description: "No more glancing at your watch. Your coach speaks to you naturally, just like a real running partner.",
      benefit: "Stay focused on your run, not your screen",
    },
    {
      icon: Heart,
      title: "Real-Time Biometrics",
      description: "PacePilot watches your heart rate, pace, and cadence — adjusting coaching based on how your body is actually responding.",
      benefit: "Train smarter, recover faster",
    },
    {
      icon: Calendar,
      title: "Adaptive Training Plans",
      description: "Plans that flex around your life. Missed a run? Feeling tired? Your coach rebalances automatically.",
      benefit: "A plan that works with your schedule",
    },
    {
      icon: Watch,
      title: "Apple Watch Integration",
      description: "Seamless sync with your Apple Watch for accurate biometrics and haptic feedback during intervals.",
      benefit: "Your wrist becomes your coach",
    },
    {
      icon: Users,
      title: "Pace-Based Communities",
      description: "Get matched with runners at your level. See their runs, compete on leaderboards, find your tribe.",
      benefit: "Never run alone again",
    },
    {
      icon: Trophy,
      title: "Race Discovery",
      description: "Find local races that match your goals. Your coach helps you peak at the right time.",
      benefit: "Cross that finish line prepared",
    },
  ];

  return (
    <section id="features" className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-gray-950 to-black">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
            Features
          </Badge>
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            Everything You Need to <span className="gradient-text">Run Your Best</span>
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto">
            PacePilot combines cutting-edge AI with deep running expertise to deliver 
            coaching that was previously only available to elite athletes.
          </p>
        </div>
        
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <Card key={index} className="bg-gray-900/30 border-white/5 hover:border-[#AAFF00]/30 transition-all hover:transform hover:scale-[1.02] group">
              <CardContent className="p-6">
                <div className="w-12 h-12 rounded-xl bg-[#AAFF00]/10 flex items-center justify-center mb-4 group-hover:bg-[#AAFF00]/20 transition-colors">
                  <feature.icon className="w-6 h-6 text-[#AAFF00]" />
                </div>
                <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
                <p className="text-gray-400 text-sm mb-4">{feature.description}</p>
                <p className="text-[#AAFF00] text-sm font-medium flex items-center gap-1">
                  <Zap className="w-4 h-4" />
                  {feature.benefit}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  );
}

function HowItWorksSection() {
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

  return (
    <section id="how-it-works" className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
            How It Works
          </Badge>
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            From Download to <span className="gradient-text">Personal Best</span>
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

function TestimonialsSection() {
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

  return (
    <section id="testimonials" className="py-20 px-4 sm:px-6 lg:px-8 bg-gradient-to-b from-black to-gray-950">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
            Testimonials
          </Badge>
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            Runners Who Found Their <span className="gradient-text">Breakthrough</span>
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto">
            Join thousands of runners who&apos;ve transformed their training with PacePilot.
          </p>
        </div>
        
        <div className="grid md:grid-cols-3 gap-6">
          {testimonials.map((testimonial, index) => (
            <Card key={index} className="bg-gray-900/50 border-white/5 hover:border-[#AAFF00]/20 transition-colors">
              <CardContent className="p-6">
                <div className="flex items-center gap-1 mb-4">
                  {[1, 2, 3, 4, 5].map((i) => (
                    <Star key={i} className="w-4 h-4 fill-[#AAFF00] text-[#AAFF00]" />
                  ))}
                </div>
                <p className="text-gray-300 mb-6 italic">&quot;{testimonial.quote}&quot;</p>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <Avatar className="w-10 h-10 bg-[#AAFF00]/20">
                      <AvatarFallback className="bg-[#AAFF00]/20 text-[#AAFF00]">{testimonial.avatar}</AvatarFallback>
                    </Avatar>
                    <div>
                      <p className="font-semibold text-sm">{testimonial.name}</p>
                      <p className="text-xs text-gray-400">{testimonial.role}</p>
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
          <p className="text-sm text-gray-400">As featured in:</p>
          <div className="flex items-center gap-8">
            {["Runner's World", "Strava", "Apple Fitness+", "Men's Health"].map((brand) => (
              <span key={brand} className="text-gray-500 font-semibold">{brand}</span>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

function PricingSection() {
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
    },
    {
      name: "Pro",
      price: "$9.99",
      period: "/month",
      description: "Unlock your full potential",
      features: [
        "Everything in Free",
        "Adaptive training plans",
        "Real-time biometric coaching",
        "Apple Watch integration",
        "Calendar sync",
        "Strava integration",
        "Priority support",
      ],
      cta: "Start Pro Trial",
      highlighted: true,
    },
    {
      name: "Team",
      price: "$29.99",
      period: "/month",
      description: "For running clubs & groups",
      features: [
        "Everything in Pro",
        "Up to 50 members",
        "Team leaderboards",
        "Group challenges",
        "Coach dashboard",
        "Custom branding",
      ],
      cta: "Contact Sales",
      highlighted: false,
    },
  ];

  return (
    <section id="pricing" className="py-20 px-4 sm:px-6 lg:px-8">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <Badge className="mb-4 bg-[#AAFF00]/10 text-[#AAFF00] border-[#AAFF00]/20">
            Pricing
          </Badge>
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            Invest in Your <span className="gradient-text">Running Journey</span>
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto">
            Start free, upgrade when you&apos;re ready. Cancel anytime.
          </p>
        </div>
        
        <div className="grid md:grid-cols-3 gap-6 max-w-5xl mx-auto">
          {plans.map((plan, index) => (
            <Card 
              key={index} 
              className={`relative ${
                plan.highlighted 
                  ? "bg-gradient-to-b from-[#AAFF00]/10 to-gray-900 border-[#AAFF00]/30 glow-border" 
                  : "bg-gray-900/50 border-white/5"
              }`}
            >
              {plan.highlighted && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                  <Badge className="bg-[#AAFF00] text-black font-semibold">Most Popular</Badge>
                </div>
              )}
              <CardContent className="p-6">
                <h3 className="text-xl font-semibold mb-2">{plan.name}</h3>
                <div className="flex items-baseline gap-1 mb-2">
                  <span className="text-4xl font-bold">{plan.price}</span>
                  <span className="text-gray-400">{plan.period}</span>
                </div>
                <p className="text-gray-400 text-sm mb-6">{plan.description}</p>
                
                <ul className="space-y-3 mb-6">
                  {plan.features.map((feature, i) => (
                    <li key={i} className="flex items-center gap-2 text-sm">
                      <ChevronRight className="w-4 h-4 text-[#AAFF00]" />
                      <span className="text-gray-300">{feature}</span>
                    </li>
                  ))}
                </ul>
                
                <Button 
                  className={`w-full ${
                    plan.highlighted 
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

function CTASection() {
  return (
    <section className="py-20 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-r from-[#AAFF00]/10 via-[#AAFF00]/5 to-[#AAFF00]/10" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-[#AAFF00]/10 rounded-full blur-3xl" />
      
      <div className="max-w-4xl mx-auto text-center relative">
        <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold mb-6">
          Ready to Run With a Coach Who <span className="gradient-text">Actually Knows You?</span>
        </h2>
        <p className="text-xl text-gray-400 mb-8 max-w-2xl mx-auto">
          Your first coached run is waiting. No credit card required. 
          Just you, your shoes, and a coach that&apos;s about to change everything.
        </p>
        
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-8">
          <Button size="lg" className="bg-[#AAFF00] text-black hover:bg-[#88CC00] text-base font-semibold px-8 animate-pulse-glow">
            Start Your Free Coached Run
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        </div>
        
        <div className="flex items-center justify-center gap-6 text-sm text-gray-400">
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

function Footer() {
  return (
    <footer className="py-12 px-4 sm:px-6 lg:px-8 border-t border-white/10">
      <div className="max-w-7xl mx-auto">
        <div className="grid md:grid-cols-4 gap-8 mb-8">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 rounded-lg bg-[#AAFF00] flex items-center justify-center">
                <Activity className="w-5 h-5 text-black" />
              </div>
              <span className="font-bold text-lg">PacePilot</span>
            </div>
            <p className="text-gray-400 text-sm">
              Your AI running coach that&apos;s with you on every run.
            </p>
          </div>
          
          <div>
            <h4 className="font-semibold mb-4">Product</h4>
            <ul className="space-y-2 text-sm text-gray-400">
              <li><a href="#features" className="hover:text-white transition-colors">Features</a></li>
              <li><a href="#pricing" className="hover:text-white transition-colors">Pricing</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Download App</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Integrations</a></li>
            </ul>
          </div>
          
          <div>
            <h4 className="font-semibold mb-4">Company</h4>
            <ul className="space-y-2 text-sm text-gray-400">
              <li><a href="#" className="hover:text-white transition-colors">About</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Blog</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Careers</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Contact</a></li>
            </ul>
          </div>
          
          <div>
            <h4 className="font-semibold mb-4">Legal</h4>
            <ul className="space-y-2 text-sm text-gray-400">
              <li><a href="#" className="hover:text-white transition-colors">Privacy Policy</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Terms of Service</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Cookie Policy</a></li>
            </ul>
          </div>
        </div>
        
        <div className="pt-8 border-t border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-sm text-gray-400">
            © 2026 PacePilot. All rights reserved.
          </p>
          <div className="flex items-center gap-4">
            <a href="#" className="text-gray-400 hover:text-white transition-colors">
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M24 4.557c-.883.392-1.832.656-2.828.775 1.017-.609 1.798-1.574 2.165-2.724-.951.564-2.005.974-3.127 1.195-.897-.957-2.178-1.555-3.594-1.555-3.179 0-5.515 2.966-4.797 6.045-4.091-.205-7.719-2.165-10.148-5.144-1.29 2.213-.669 5.108 1.523 6.574-.806-.026-1.566-.247-2.229-.616-.054 2.281 1.581 4.415 3.949 4.89-.693.188-1.452.232-2.224.084.626 1.956 2.444 3.379 4.6 3.419-2.07 1.623-4.678 2.348-7.29 2.04 2.179 1.397 4.768 2.212 7.548 2.212 9.142 0 14.307-7.721 13.995-14.646.962-.695 1.797-1.562 2.457-2.549z"/></svg>
            </a>
            <a href="#" className="text-gray-400 hover:text-white transition-colors">
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
            </a>
            <a href="#" className="text-gray-400 hover:text-white transition-colors">
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"/></svg>
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
