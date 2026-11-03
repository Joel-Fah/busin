import Link from "next/link";
import type { ButtonHTMLAttributes, ReactNode } from "react";
import type { IconSvgElement } from "@hugeicons/react";

import { Contour } from "./Contour";
import { Icon } from "./Icon";

export type ButtonVariant = "primary" | "secondary" | "ghost" | "danger";

const VARIANTS: Record<ButtonVariant, string> = {
  primary: "bg-accent text-on-accent hover:brightness-105 active:brightness-95",
  secondary: "bg-surface-2 text-fg hover:bg-line",
  ghost: "bg-transparent text-fg hover:bg-surface-2",
  danger: "bg-bad-bg text-bad hover:brightness-95",
};

const BASE =
  "relative inline-flex h-11 cursor-pointer items-center border-0 font-sans no-underline justify-center gap-2 rounded-sm px-5 text-sm font-semibold " +
  "transition-[background-color,filter,transform] duration-(--dur-fast) ease-soft active:scale-[0.98] " +
  "focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-focus " +
  "disabled:pointer-events-none disabled:opacity-50 motion-reduce:transition-none";

type Common = {
  variant?: ButtonVariant;
  icon?: IconSvgElement;
  children: ReactNode;
  className?: string;
};

function Inner({ variant, icon, children }: Pick<Common, "variant" | "icon" | "children">) {
  return (
    <>
      {variant === "primary" || variant === "secondary" ? <Contour radius={12} inset={4} dash={[4, 5]} /> : null}
      {icon ? <Icon icon={icon} size={18} /> : null}
      <span>{children}</span>
    </>
  );
}

export function Button({
  variant = "primary",
  icon,
  children,
  className = "",
  type = "button",
  ...rest
}: Common & Omit<ButtonHTMLAttributes<HTMLButtonElement>, keyof Common>) {
  return (
    <button type={type} className={`${BASE} ${VARIANTS[variant]} ${className}`} {...rest}>
      <Inner variant={variant} icon={icon}>
        {children}
      </Inner>
    </button>
  );
}

/** The same look as a link, for navigation. */
export function ButtonLink({
  variant = "primary",
  icon,
  children,
  className = "",
  href,
}: Common & { href: string }) {
  return (
    <Link href={href} className={`${BASE} ${VARIANTS[variant]} ${className}`}>
      <Inner variant={variant} icon={icon}>
        {children}
      </Inner>
    </Link>
  );
}
