// The styleguide is documentation, so it is shown without the portal's navigation bar.
// Each page still checks that the visitor is an administrator.
export default function GuideLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="mx-auto flex w-full max-w-7xl min-w-0 flex-col gap-6 px-[clamp(1rem,4vw,2.5rem)] pt-6 pb-24">
      {children}
    </main>
  );
}
