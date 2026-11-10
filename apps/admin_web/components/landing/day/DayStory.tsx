"use client";

import { useRef } from "react";

import type { LandingCopy } from "@/lib/i18n/landing";

import { useScrollScene } from "../motion/useScrollScene";
import { Phone } from "../devices/Devices";
import { DayScreen } from "./DayScreens";

/**
 * A student's morning in four steps. On a wide screen the phone stays in place while the steps scroll past, and its
 * screen follows the step in the middle of the window (the root's data-step, read by landing.css). On a phone each step
 * carries its own small phone. Without scripts the steps and the first screen are all there; nothing depends on motion.
 */
/** The time as a phone's clock shows it: "6 h 40" becomes "6:40". */
const clock = (time: string) => time.replace(/\s*h\s*/, ":");

export function DayStory({ copy }: { copy: LandingCopy["day"] }) {
  const ref = useRef<HTMLDivElement>(null);

  useScrollScene(ref, ({ ScrollTrigger, wide, root }) => {
    if (!wide) return;
    const steps = Array.from(root.querySelectorAll<HTMLElement>("[data-day-step]"));
    const triggers = steps.map((step, i) =>
      ScrollTrigger.create({
        trigger: step,
        start: "top 55%",
        end: "bottom 55%",
        onToggle: (self) => {
          if (self.isActive) root.dataset.step = String(i);
        },
      }),
    );
    return () => {
      triggers.forEach((t) => t.kill());
      root.dataset.step = "0";
    };
  });

  return (
    <div ref={ref} data-step="0" className="day-story mt-14 grid gap-14 lg:mt-20 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.1fr)] lg:gap-20">
      <div className="hidden lg:block">
        <div className="sticky top-[14vh]">
          <div aria-hidden className="absolute -inset-x-[14%] -inset-y-[8%] bg-[radial-gradient(closest-side,rgb(245_149_31/0.2),transparent)] dark:bg-[radial-gradient(closest-side,rgb(0_180_201/0.16),transparent)]" />
          <Phone
            className="w-[16.5rem]"
            time={copy.steps.map((step, i) => (
              <span key={step.time} data-time={i} className="day-time">
                {clock(step.time)}
              </span>
            ))}
          >
            {copy.steps.map((step, i) => (
              <div key={step.time} data-screen={i} className="day-screen absolute inset-0">
                <DayScreen index={i} copy={copy} />
              </div>
            ))}
          </Phone>
        </div>
      </div>

      <ol className="m-0 flex list-none flex-col gap-16 p-0 lg:gap-0">
        {copy.steps.map((step, i) => (
          <li key={step.time} data-day-step={i} className="day-step flex flex-col gap-6 lg:min-h-[78vh] lg:justify-center">
            <div className="flex flex-col gap-3">
              <p className="m-0 flex items-center gap-3 text-sm font-bold text-muted">
                <span className="rounded-xs bg-accent px-2.5 py-1 font-extrabold tabular-nums text-on-accent">{step.time}</span>
                <span aria-hidden className="h-px w-10 border-t border-dashed border-line" />
                {i + 1} / {copy.steps.length}
              </p>
              <h3 className="m-0 text-3xl font-extrabold tracking-tight sm:text-4xl">{step.title}</h3>
              <p className="m-0 max-w-[30rem] text-pretty text-lg leading-relaxed text-muted">{step.text}</p>
            </div>
            <div className="lg:hidden">
              <Phone className="day-inline w-[16.5rem]" time={clock(step.time)} kind={i % 2 ? "android" : "iphone"}>
                <div className="day-screen is-shown absolute inset-0">
                  <DayScreen index={i} copy={copy} />
                </div>
              </Phone>
            </div>
          </li>
        ))}
      </ol>
    </div>
  );
}
