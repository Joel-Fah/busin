/**
 * The styleguide as a PDF for reading and printing: A4, a cover, a contents page with links, then one part per section
 * with real swatches, type samples and shapes, and page numbers. Built from the same content as the page. Light theme
 * only, since paper is white; the dark values are listed beside the light ones.
 */
import { fileURLToPath } from "node:url";

import { Document, Font, Link, Page, StyleSheet, Text, View, renderToBuffer } from "@react-pdf/renderer";
import type { ReactNode } from "react";

import { AA_TEXT, contrastRatio } from "@/lib/ui/contrast";
import { RADIUS, innerRadius } from "@/lib/ui/radius";
import { DARK, LIGHT, TEXT_PAIRS } from "@/lib/ui/tokens";

import {
  AUDIENCE,
  COLOUR_STATE_NOTE,
  COMPONENT_NOTES,
  GRAIN_NOTE,
  GUIDE,
  ILLUSTRATION_NOTE,
  LOGO_MOTION,
  MOTION_NOTE,
  MOTION_STEPS,
  NAV_HELP,
  NAV_RULES,
  NEVER,
  PEOPLE_STYLE,
  PHOTO_NOTE,
  PRINCIPLES,
  RADIUS_USE,
  RAMPS,
  ROUGH_NOTE,
  SECTIONS,
  SEED,
  TEXTURE_USE,
  THREE_D,
  TOKEN_USE,
  TYPE_NOTE,
  TYPE_SCALE,
  VOICE_PAIRS,
  VOICE_RULES,
  section,
  type SectionId,
} from "./content";

const FAMILY = "Plus Jakarta Sans";
let fontsReady = false;

/** The brand face, from the files the share images already use (assets/og). */
function registerFonts() {
  if (fontsReady) return;
  Font.register({
    family: FAMILY,
    fonts: [
      { src: fileURLToPath(new URL("../../assets/og/pjs-medium.ttf", import.meta.url)), fontWeight: 500 },
      { src: fileURLToPath(new URL("../../assets/og/pjs-extrabold.ttf", import.meta.url)), fontWeight: 800 },
    ],
  });
  // Whole words only: no hyphens breaking product words.
  Font.registerHyphenationCallback((word) => [word]);
  fontsReady = true;
}

const C = LIGHT;

const styles = StyleSheet.create({
  page: { fontFamily: FAMILY, fontWeight: 500, fontSize: 10, lineHeight: 1.5, color: C.fg, backgroundColor: "#ffffff", paddingTop: 52, paddingBottom: 60, paddingHorizontal: 52 },
  footer: { position: "absolute", bottom: 26, left: 52, right: 52, flexDirection: "row", justifyContent: "space-between", fontSize: 8, color: C.muted },
  h1: { fontSize: 26, fontWeight: 800, letterSpacing: -0.5, lineHeight: 1.15, marginBottom: 6 },
  h2: { fontSize: 13, fontWeight: 800, marginTop: 16, marginBottom: 6 },
  intro: { fontSize: 11, color: C.muted, marginBottom: 12, maxWidth: 440 },
  body: { marginBottom: 8 },
  small: { fontSize: 8.5, color: C.muted },
  bullet: { flexDirection: "row", marginBottom: 4 },
  dot: { width: 12, color: C.accent, fontWeight: 800 },
  panel: { backgroundColor: C["surface-2"], borderRadius: RADIUS.sm, padding: 12, marginBottom: 8 },
  row: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  th: { fontSize: 8, fontWeight: 800, color: C.muted, textTransform: "uppercase", letterSpacing: 0.6 },
  tr: { flexDirection: "row", borderTopWidth: 0.6, borderTopColor: C.line, paddingVertical: 5 },
});

function Bullets({ items }: { items: string[] }) {
  return (
    <View style={{ marginBottom: 8 }}>
      {items.map((item) => (
        <View key={item} style={styles.bullet} wrap={false}>
          <Text style={styles.dot}>-</Text>
          <Text style={{ flex: 1 }}>{item}</Text>
        </View>
      ))}
    </View>
  );
}

/** A simple table: column widths as flex weights. */
function Table({ head, rows, widths }: { head: string[]; rows: ReactNode[][]; widths: number[] }) {
  return (
    <View style={{ marginBottom: 10 }}>
      <View style={{ flexDirection: "row", paddingBottom: 4 }} fixed={false}>
        {head.map((h, i) => (
          <Text key={h} style={[styles.th, { flex: widths[i] }]}>
            {h}
          </Text>
        ))}
      </View>
      {rows.map((cells, r) => (
        <View key={r} style={styles.tr} wrap={false}>
          {cells.map((c, i) => (
            <View key={i} style={{ flex: widths[i], paddingRight: 6 }}>
              {typeof c === "string" ? <Text>{c}</Text> : c}
            </View>
          ))}
        </View>
      ))}
    </View>
  );
}

function Part({ id, children }: { id: SectionId; children: ReactNode }) {
  const { title, intro } = section(id);
  return (
    <Page size="A4" style={styles.page} id={id}>
      <Text style={styles.small}>{GUIDE.name.toUpperCase()}</Text>
      <Text style={[styles.h1, { marginTop: 4 }]}>{title}</Text>
      <Text style={styles.intro}>{intro}</Text>
      {children}
      <Footer />
    </Page>
  );
}

function Footer() {
  return (
    <View style={styles.footer} fixed>
      <Text>{GUIDE.name}</Text>
      <Text render={({ pageNumber, totalPages }) => `${pageNumber} / ${totalPages}`} />
    </View>
  );
}

function Swatch({ name }: { name: string }) {
  return (
    <View style={{ width: "23.5%", marginBottom: 8 }} wrap={false}>
      <View style={{ height: 34, borderRadius: RADIUS.xs, backgroundColor: LIGHT[name], borderWidth: 0.6, borderColor: C.line, flexDirection: "row", overflow: "hidden" }}>
        <View style={{ flex: 1 }} />
        {/* The dark theme value, as a corner. */}
        <View style={{ width: 22, backgroundColor: DARK[name] }} />
      </View>
      <Text style={{ fontWeight: 800, fontSize: 9, marginTop: 3 }}>{name}</Text>
      <Text style={styles.small}>
        {LIGHT[name]} / {DARK[name]}
      </Text>
    </View>
  );
}

function StyleguideDocument({ generatedOn }: { generatedOn: string }) {
  const steps = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
  return (
    <Document title={`${GUIDE.name}: ${GUIDE.title}`} author="BusIn" subject={GUIDE.summary} language="en">
      {/* Cover */}
      <Page size="A4" style={[styles.page, { backgroundColor: SEED, color: "#ffffff", justifyContent: "flex-end", paddingBottom: 72 }]}>
        <View style={{ position: "absolute", top: 52, left: 52, right: 52, height: 6, flexDirection: "row", gap: 4 }}>
          {steps.map((n) => (
            <View key={n} style={{ flex: 1, backgroundColor: RAMPS.teal[n], borderRadius: 3 }} />
          ))}
        </View>
        <Text style={{ fontSize: 12, color: RAMPS.teal[200] }}>{GUIDE.name}</Text>
        <Text style={{ fontSize: 52, fontWeight: 800, letterSpacing: -1.5, lineHeight: 1.05, marginTop: 6 }}>{GUIDE.title}</Text>
        <Text style={{ fontSize: 13, marginTop: 12, maxWidth: 380, color: "#e6f4f4" }}>{GUIDE.summary}</Text>
        <View style={{ marginTop: 28, height: 4, width: 64, backgroundColor: C.accent, borderRadius: 2 }} />
        <Text style={{ fontSize: 9, marginTop: 14, color: RAMPS.teal[200] }}>Generated {generatedOn}</Text>
      </Page>

      {/* Contents */}
      <Page size="A4" style={styles.page}>
        <Text style={styles.h1}>Contents</Text>
        <Text style={styles.intro}>{AUDIENCE}</Text>
        {SECTIONS.map((s, i) => (
          <Link key={s.id} src={`#${s.id}`} style={{ textDecoration: "none", color: C.fg }}>
            <View style={[styles.tr, { paddingVertical: 7 }]}>
              <Text style={{ width: 28, color: C.muted }}>{String(i + 1).padStart(2, "0")}</Text>
              <Text style={{ fontWeight: 800, flex: 1 }}>{s.title}</Text>
            </View>
          </Link>
        ))}
        <Footer />
      </Page>

      <Part id="overview">
        <View style={styles.row}>
          {PRINCIPLES.map(([title, body]) => (
            <View key={title} style={[styles.panel, { width: "31.5%" }]} wrap={false}>
              <Text style={{ fontWeight: 800, fontSize: 12, marginBottom: 4 }}>{title}</Text>
              <Text>{body}</Text>
            </View>
          ))}
        </View>
      </Part>

      <Part id="voice">
        <Bullets items={VOICE_RULES} />
        <Table
          head={["Do", "Do not"]}
          widths={[1, 1]}
          rows={VOICE_PAIRS.map((p) => [<Text key="d" style={{ color: C.ok }}>{p.do}</Text>, <Text key="n" style={{ color: C.bad }}>{p.dont}</Text>])}
        />
        <Text style={styles.h2} id="logo">
          {section("logo").title}
        </Text>
        <Text style={styles.body}>{section("logo").intro}</Text>
        <Text style={styles.small}>{LOGO_MOTION}</Text>
      </Part>

      <Part id="colour">
        <Text style={styles.h2}>Surface and text tokens</Text>
        <Text style={[styles.small, { marginBottom: 6 }]}>Each swatch shows the light value, with the dark value at its right edge.</Text>
        <View style={styles.row}>
          {["bg", "surface", "surface-2", "line", "fg", "muted", "brand", "accent", "link"].map((n) => (
            <Swatch key={n} name={n} />
          ))}
        </View>
        <Text style={styles.h2}>State tokens</Text>
        <Text style={[styles.small, { marginBottom: 6 }]}>{COLOUR_STATE_NOTE}</Text>
        <View style={styles.row}>
          {["ok", "ok-bg", "warn", "warn-bg", "bad", "bad-bg", "info", "info-bg"].map((n) => (
            <Swatch key={n} name={n} />
          ))}
        </View>
        <Text style={styles.h2} break>
          What each token is for
        </Text>
        <Table head={["Token", "Light", "Dark", "Use"]} widths={[1.1, 0.9, 0.9, 2.4]} rows={Object.keys(LIGHT).map((n) => [n, LIGHT[n], DARK[n], TOKEN_USE[n] ?? ""])} />
        <Text style={styles.h2}>Brand ramps</Text>
        {(["teal", "orange"] as const).map((ramp) => (
          <View key={ramp} style={{ flexDirection: "row", gap: 3, marginBottom: 8 }} wrap={false}>
            {steps.map((n) => (
              <View key={n} style={{ flex: 1 }}>
                <View style={{ height: 26, borderRadius: 4, backgroundColor: RAMPS[ramp][n] }} />
                <Text style={[styles.small, { textAlign: "center", fontSize: 7 }]}>
                  {ramp} {n}
                </Text>
              </View>
            ))}
          </View>
        ))}
        <Text style={styles.h2}>Contrast (WCAG AA needs {AA_TEXT}:1 for text)</Text>
        <Table
          head={["Pair", "Light", "Dark"]}
          widths={[2, 1, 1]}
          rows={TEXT_PAIRS.map(([fg, bg]) => [`${fg} on ${bg}`, `${contrastRatio(LIGHT[fg], LIGHT[bg]).toFixed(1)}:1`, `${contrastRatio(DARK[fg], DARK[bg]).toFixed(1)}:1`])}
        />
      </Part>

      <Part id="type">
        <View style={[styles.panel, { padding: 18 }]}>
          {TYPE_SCALE.map((t) => (
            <Text
              key={t.role}
              style={{
                // Print sizes: the screen px scale read as points, the largest eased down to fit the page.
                fontSize: Math.min(t.size, 34),
                fontWeight: t.weight >= 600 ? 800 : 500,
                color: t.extra?.includes("muted") ? C.muted : C.fg,
                textTransform: t.extra?.includes("uppercase") ? "uppercase" : "none",
                letterSpacing: t.extra?.includes("tight") ? -0.5 : t.extra?.includes("wide") ? 1 : 0,
                lineHeight: t.size >= 30 ? 1.15 : 1.5,
                marginBottom: 8,
              }}
            >
              {t.sample}
            </Text>
          ))}
        </View>
        <Text style={styles.body}>{TYPE_NOTE}</Text>
      </Part>

      <Part id="shape">
        <View style={[styles.row, { alignItems: "flex-start", marginBottom: 12 }]}>
          {Object.entries(RADIUS).map(([name, px]) => (
            <View key={name} style={{ width: "18%" }} wrap={false}>
              <View style={{ height: 60, borderRadius: px, backgroundColor: C["surface-2"] }} />
              <Text style={{ fontWeight: 800, marginTop: 4 }}>
                {name} <Text style={styles.small}>{px}px</Text>
              </Text>
              <Text style={styles.small}>{RADIUS_USE[name]}</Text>
            </View>
          ))}
        </View>
        <View style={{ flexDirection: "row", alignItems: "center", gap: 16 }} wrap={false}>
          <View style={{ backgroundColor: C["surface-2"], padding: 16, borderRadius: RADIUS.lg }}>
            <View style={{ width: 110, height: 56, backgroundColor: C.accent, borderRadius: innerRadius(RADIUS.lg, 16) }} />
          </View>
          <Text style={{ flex: 1 }}>
            Outer {RADIUS.lg}px, padding 16px, inner {innerRadius(RADIUS.lg, 16)}px: the inner radius is the outer radius minus the padding.
          </Text>
        </View>
        <Text style={styles.h2} id="contour">
          {section("contour").title}
        </Text>
        <Text style={styles.body}>{section("contour").intro}</Text>
        <View style={{ borderRadius: RADIUS.lg, backgroundColor: C.surface, padding: 10, borderWidth: 0.6, borderColor: C.line }} wrap={false}>
          <View style={{ borderRadius: RADIUS.lg - 10, borderWidth: 1.2, borderStyle: "dashed", borderColor: C.muted, padding: 14 }}>
            <Text style={{ fontWeight: 800 }}>A card with its thread</Text>
            <Text style={styles.small}>The stitched thread runs inside the edge; on screen it is round-capped dashes.</Text>
          </View>
        </View>
      </Part>

      <Part id="texture">
        <Text style={styles.h2}>Grain</Text>
        <Text style={styles.body}>{GRAIN_NOTE}</Text>
        <Text style={styles.h2}>Rough edge</Text>
        <Text style={styles.body}>{ROUGH_NOTE}</Text>
        <Text style={styles.h2}>In use</Text>
        <Bullets items={TEXTURE_USE} />
        <Text style={styles.h2} id="icons">
          {section("icons").title}
        </Text>
        <Text style={styles.body}>{section("icons").intro}</Text>
      </Part>

      <Part id="navigation">
        <Bullets items={NAV_RULES} />
        <Text style={styles.h2}>Page header and help</Text>
        <Text style={styles.body}>{NAV_HELP}</Text>
      </Part>

      <Part id="motion">
        <View style={styles.row}>
          {MOTION_STEPS.map((m) => (
            <View key={m.name} style={[styles.panel, { width: "31.5%" }]} wrap={false}>
              <Text style={{ fontSize: 20, fontWeight: 800, lineHeight: 1.2, marginBottom: 2 }}>{m.ms}ms</Text>
              <Text style={{ fontWeight: 800 }}>{m.name}</Text>
              <Text style={styles.small}>{m.use}</Text>
            </View>
          ))}
        </View>
        <Text style={styles.body}>{MOTION_NOTE}</Text>
      </Part>

      <Part id="imagery">
        <Text style={styles.h2}>People illustrations</Text>
        <Text style={styles.body}>{PEOPLE_STYLE.intro}</Text>
        <Bullets items={PEOPLE_STYLE.rules} />
        <View style={[styles.row, { marginBottom: 8 }]} wrap={false}>
          {PEOPLE_STYLE.palette.map(([name, hex]) => (
            <View key={name} style={{ width: "9%" }}>
              <View style={{ height: 22, borderRadius: 4, backgroundColor: hex }} />
              <Text style={[styles.small, { fontSize: 6.5 }]}>{name}</Text>
            </View>
          ))}
        </View>
        <Text style={styles.h2}>3D objects</Text>
        <Text style={styles.body}>{ILLUSTRATION_NOTE}</Text>
        <Text style={styles.small}>The set: {THREE_D.map(([, label]) => label).join(", ")}.</Text>
        <Text style={styles.h2}>Photographs</Text>
        <Text style={styles.body}>{PHOTO_NOTE}</Text>
      </Part>

      <Part id="components">
        {COMPONENT_NOTES.map((c) => (
          <View key={c.name} style={{ marginBottom: 8 }} wrap={false}>
            <Text style={{ fontWeight: 800, fontSize: 11, marginBottom: 2 }}>{c.name}</Text>
            <Text>{c.note}</Text>
          </View>
        ))}
      </Part>

      <Part id="rules">
        <View style={styles.row}>
          {NEVER.map((rule) => (
            <View key={rule} style={[styles.panel, { width: "48.5%", backgroundColor: C["bad-bg"] }]} wrap={false}>
              <Text style={{ color: C.bad, fontWeight: 800 }}>{rule}</Text>
            </View>
          ))}
        </View>
      </Part>
    </Document>
  );
}

export async function buildPdf({ generatedOn }: { generatedOn: string }): Promise<Buffer> {
  registerFonts();
  return renderToBuffer(<StyleguideDocument generatedOn={generatedOn} />);
}
