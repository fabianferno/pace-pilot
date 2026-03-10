"use client";

import {
  Header,
  HeroSection,
  ProblemSection,
  SolutionSection,
  FeaturesSection,
  HowItWorksSection,
  TestimonialsSection,
  PricingSection,
  CTASection,
  Footer,
} from "@/components/landing";

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
