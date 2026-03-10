import { Button } from "@/components/ui/button";
import Link from "next/link";

export function Header() {
  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 max-w-7xl mx-auto  backdrop-blur-lg border-b border-white/20 rounded-b-xl">
      <div className="px-4 sm:px-6 lg:px-3">
        <div className="flex items-center justify-between h-16">
          <Link href="/" className="flex items-center gap-3">
            <img
              src="/logo/logo.png"
              alt="PacePilot"
              className="w-12 h-12 object-contain border border-zinc-600 rounded-md -p-4"
            />
            <span className="font-bold text-lg">PacePilot</span>
          </Link>
          <nav className="hidden md:flex items-center gap-8">
            <a href="#features" className="text-sm text-zinc-400 hover:text-white transition-colors">Features</a>
            <a href="#how-it-works" className="text-sm text-zinc-400 hover:text-white transition-colors">How It Works</a>
            <a href="#testimonials" className="text-sm text-zinc-400 hover:text-white transition-colors">Testimonials</a>
            <a href="#pricing" className="text-sm text-zinc-400 hover:text-white transition-colors">Pricing</a>
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
