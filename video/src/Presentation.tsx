import React from "react";
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";
import { TransitionSeries, linearTiming } from "@remotion/transitions";
import { fade } from "@remotion/transitions/fade";
import { slide } from "@remotion/transitions/slide";
import { loadFont as loadSerif } from "@remotion/google-fonts/CormorantGaramond";
import { loadFont as loadSans } from "@remotion/google-fonts/PlusJakartaSans";

const serif = loadSerif("normal", { weights: ["500", "600"] }).fontFamily;
const serifItalic = loadSerif("italic", { weights: ["500"] }).fontFamily;
const sans = loadSans("normal", { weights: ["400", "500", "700"] }).fontFamily;

// Les couleurs de l'app (lib/theme/app_theme.dart).
const gold = "#F5B700";
const goldSoft = "#F2CC5C";
const ink = "#07080B";
const text = "#F4F2EE";
const muted = "#A3A3A8";

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;
const ease = Easing.bezier(0.16, 1, 0.3, 1);

/** Apparition douce : monte de quelques pixels et devient visible. */
const useRise = (delay: number, distance = 40) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 200 } });
  return { opacity: s, transform: `translateY(${(1 - s) * distance}px)` };
};

const Rise: React.FC<{
  delay?: number;
  style?: React.CSSProperties;
  children: React.ReactNode;
}> = ({ delay = 0, style, children }) => {
  const rise = useRise(delay);
  return <div style={{ ...style, ...rise }}>{children}</div>;
};

/** Fond sombre, halo doré qui dérive, fine grille. */
const Backdrop: React.FC = () => {
  const frame = useCurrentFrame();
  const x = 30 + 30 * Math.sin(frame / 110);
  const y = 40 + 18 * Math.cos(frame / 140);
  return (
    <AbsoluteFill style={{ backgroundColor: ink }}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle at ${x}% ${y}%, ${gold}40 0%, transparent 45%), radial-gradient(circle at ${100 - x}% ${95 - y}%, #6b8cff26 0%, transparent 50%)`,
        }}
      />
      <AbsoluteFill
        style={{
          backgroundImage:
            "linear-gradient(#ffffff08 1px, transparent 1px), linear-gradient(90deg, #ffffff08 1px, transparent 1px)",
          backgroundSize: "80px 80px",
          maskImage: "radial-gradient(circle at 50% 50%, black 0%, transparent 75%)",
        }}
      />
    </AbsoluteFill>
  );
};

const Eyebrow: React.FC<{ children: React.ReactNode; delay?: number }> = ({
  children,
  delay = 0,
}) => (
  <Rise delay={delay}>
    <div
      style={{
        fontFamily: sans,
        fontWeight: 700,
        fontSize: 24,
        letterSpacing: 8,
        textTransform: "uppercase",
        color: gold,
      }}
    >
      {children}
    </div>
  </Rise>
);

const Heading: React.FC<{
  children: React.ReactNode;
  delay?: number;
  size?: number;
}> = ({ children, delay = 4, size = 92 }) => (
  <Rise delay={delay}>
    <div
      style={{
        fontFamily: serif,
        fontWeight: 600,
        fontSize: size,
        lineHeight: 1.02,
        color: text,
        marginTop: 18,
      }}
    >
      {children}
    </div>
  </Rise>
);

const Chip: React.FC<{ label: string; delay: number; strong?: boolean }> = ({
  label,
  delay,
  strong,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({ frame: frame - delay, fps, config: { damping: 14, stiffness: 140 } });
  return (
    <div
      style={{
        fontFamily: sans,
        fontWeight: 500,
        fontSize: 30,
        padding: "16px 30px",
        borderRadius: 999,
        color: strong ? ink : text,
        background: strong ? gold : "#ffffff10",
        border: `1px solid ${strong ? gold : "#ffffff24"}`,
        opacity: s,
        transform: `scale(${0.6 + 0.4 * s})`,
      }}
    >
      {label}
    </div>
  );
};

/* ---------------------------------------------------------------- Scènes */

const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const title = "Ride with Yan";
  const line = interpolate(frame, [20, 60], [0, 1], { ...clamp, easing: ease });
  const logo = spring({ frame, fps, config: { damping: 12 } });
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center" }}>
      <Img
        src={staticFile("app/logo.png")}
        style={{
          width: 150,
          height: 150,
          borderRadius: 34,
          opacity: logo,
          transform: `scale(${0.5 + 0.5 * logo}) rotate(${(1 - logo) * -20}deg)`,
          boxShadow: `0 30px 80px ${gold}55`,
        }}
      />
      <div style={{ display: "flex", marginTop: 34 }}>
        {title.split("").map((char, i) => {
          const s = spring({
            frame: frame - 8 - i * 2,
            fps,
            config: { damping: 14, stiffness: 120 },
          });
          return (
            <span
              key={i}
              style={{
                fontFamily: serif,
                fontWeight: 600,
                fontSize: 170,
                lineHeight: 1,
                color: text,
                display: "inline-block",
                whiteSpace: "pre",
                opacity: s,
                transform: `translateY(${(1 - s) * 100}px)`,
              }}
            >
              {char}
            </span>
          );
        })}
      </div>
      <div
        style={{ marginTop: 26, height: 4, width: 420 * line, background: gold, borderRadius: 4 }}
      />
      <Rise delay={40} style={{ marginTop: 36 }}>
        <div style={{ fontFamily: sans, fontSize: 40, color: text, textAlign: "center" }}>
          L'app que j'ai conçue et codée seul pour la tablette de ma voiture.
        </div>
      </Rise>
      <Rise delay={52} style={{ marginTop: 16 }}>
        <div style={{ fontFamily: sans, fontSize: 28, color: muted, letterSpacing: 2 }}>
          Ottawa–Gatineau · Français / English
        </div>
      </Rise>
    </AbsoluteFill>
  );
};

/** Une capture de l'app dans un cadre de tablette, avec sa légende à gauche. */
const Screen: React.FC<{
  image: string;
  step: string;
  title: string;
  lines: string[];
}> = ({ image, step, title, lines }) => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const enter = spring({ frame: frame - 4, fps, config: { damping: 200 } });
  const zoom = interpolate(frame, [0, durationInFrames], [1, 1.06]);
  return (
    <AbsoluteFill style={{ flexDirection: "row", alignItems: "center", padding: "0 90px" }}>
      <div style={{ width: 560, paddingRight: 40 }}>
        <Eyebrow>{step}</Eyebrow>
        <Heading size={78}>{title}</Heading>
        <div style={{ marginTop: 34 }}>
          {lines.map((l, i) => (
            <Rise key={l} delay={14 + i * 6}>
              <div
                style={{
                  display: "flex",
                  gap: 16,
                  fontFamily: sans,
                  fontSize: 30,
                  lineHeight: 1.35,
                  color: text,
                  marginBottom: 16,
                }}
              >
                <span style={{ color: gold }}>—</span>
                <span>{l}</span>
              </div>
            </Rise>
          ))}
        </div>
      </div>
      <div
        style={{
          width: 1160,
          height: 725,
          borderRadius: 40,
          padding: 16,
          background: "#14151a",
          boxShadow: `0 60px 140px #000000cc, 0 0 0 2px #ffffff1a, 0 0 120px ${gold}22`,
          opacity: enter,
          transform: `translateX(${(1 - enter) * 160}px) perspective(2000px) rotateY(${(1 - enter) * -12}deg)`,
        }}
      >
        <div style={{ width: "100%", height: "100%", borderRadius: 26, overflow: "hidden" }}>
          <Img
            src={staticFile(`app/${image}.png`)}
            style={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
              transform: `scale(${zoom})`,
              transformOrigin: "60% 40%",
            }}
          />
        </div>
      </div>
    </AbsoluteFill>
  );
};

/** Une case du schéma de l'assistant. */
const Node: React.FC<{
  title: string;
  sub: string;
  delay: number;
  accent?: boolean;
}> = ({ title, sub, delay, accent }) => {
  const rise = useRise(delay, 30);
  return (
    <div
      style={{
        ...rise,
        width: 380,
        padding: "30px 32px",
        borderRadius: 28,
        background: accent ? `${gold}1f` : "#ffffff0d",
        border: `2px solid ${accent ? gold : "#ffffff22"}`,
      }}
    >
      <div style={{ fontFamily: sans, fontWeight: 700, fontSize: 34, color: text }}>{title}</div>
      <div style={{ fontFamily: sans, fontSize: 25, color: muted, marginTop: 10, lineHeight: 1.35 }}>
        {sub}
      </div>
    </div>
  );
};

const Arrow: React.FC<{ delay: number }> = ({ delay }) => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [delay, delay + 14], [0, 1], { ...clamp, easing: ease });
  return (
    <div style={{ width: 90, display: "flex", alignItems: "center" }}>
      <div style={{ height: 4, width: 70 * p, background: gold, borderRadius: 4 }} />
      <div
        style={{
          width: 0,
          height: 0,
          borderTop: "12px solid transparent",
          borderBottom: "12px solid transparent",
          borderLeft: `18px solid ${gold}`,
          opacity: p,
        }}
      />
    </div>
  );
};

const Assistant: React.FC = () => (
  <AbsoluteFill style={{ padding: "110px 120px", justifyContent: "center" }}>
    <Eyebrow>Intelligence artificielle</Eyebrow>
    <Heading>Yan répond aux passagers, à l'écrit et à voix haute.</Heading>
    <div style={{ display: "flex", alignItems: "center", marginTop: 70 }}>
      <Node title="Tablette" sub="Le passager pose sa question" delay={18} />
      <Arrow delay={28} />
      <Node title="Fonction serveur" sub="Supabase Edge · TypeScript · quotas" delay={32} />
      <Arrow delay={42} />
      <Node title="Azure AI Foundry" sub="GPT-4.1-mini, hébergé au Canada" delay={46} accent />
    </div>
    <div style={{ display: "flex", gap: 20, marginTop: 60, flexWrap: "wrap" }}>
      <Chip label="Azure AI Speech · voix québécoise" delay={62} />
      <Chip label="Prompt engineering" delay={68} />
      <Chip label="Filtres de contenu" delay={74} />
      <Chip label="Clé d'API jamais dans l'app" delay={80} />
    </div>
  </AbsoluteFill>
);

const Stack: React.FC = () => {
  const groups: { label: string; items: string[] }[] = [
    { label: "App", items: ["Flutter", "Dart", "Android", "Web · WebAssembly"] },
    { label: "Données", items: ["Supabase", "PostgreSQL", "Sécurité par ligne (RLS)", "Deno · TypeScript"] },
    { label: "Cloud et IA", items: ["Azure AI Foundry", "Azure AI Speech", "AI Search · RAG", "Sentry"] },
    { label: "DevOps", items: ["Terraform", "Docker", "GitHub Actions", "Azure Pipelines"] },
  ];
  return (
    <AbsoluteFill style={{ padding: "100px 120px", justifyContent: "center" }}>
      <Eyebrow>La stack</Eyebrow>
      <Heading>Du code à la production, de bout en bout.</Heading>
      <div style={{ marginTop: 60, display: "flex", flexDirection: "column", gap: 26 }}>
        {groups.map((g, gi) => (
          <div key={g.label} style={{ display: "flex", alignItems: "center", gap: 20 }}>
            <Rise delay={14 + gi * 10} style={{ width: 230 }}>
              <div style={{ fontFamily: sans, fontWeight: 700, fontSize: 26, color: goldSoft, letterSpacing: 3, textTransform: "uppercase" }}>
                {g.label}
              </div>
            </Rise>
            {g.items.map((item, i) => (
              <Chip key={item} label={item} delay={18 + gi * 10 + i * 3} strong={i === 0} />
            ))}
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};

const terraform = [
  'resource "azurerm_cognitive_account" "foundry" {',
  '  name     = "ai-ride-with-yan"',
  '  kind     = "AIServices"',
  '  location = "canadaeast"',
  "}",
  "",
  'resource "azurerm_cognitive_deployment" "assistant" {',
  '  model { name = "gpt-4.1-mini" }',
  "}",
];

const Infra: React.FC = () => {
  const frame = useCurrentFrame();
  const all = terraform.join("\n");
  const shown = Math.floor(interpolate(frame, [16, 110], [0, all.length], clamp));
  const visible = all.slice(0, shown);
  return (
    <AbsoluteFill style={{ flexDirection: "row", alignItems: "center", padding: "0 120px", gap: 80 }}>
      <div style={{ width: 640 }}>
        <Eyebrow>Infrastructure en code</Eyebrow>
        <Heading size={84}>Terraform crée tout Azure, sans un clic.</Heading>
        <Rise delay={22} style={{ marginTop: 34 }}>
          <div style={{ fontFamily: sans, fontSize: 30, color: muted, lineHeight: 1.45 }}>
            Foundry, le modèle de Yan, la voix, AI Search et les services d'IA : tout est
            décrit, relu et recréable en une commande.
          </div>
        </Rise>
      </div>
      <Rise delay={8} style={{ flex: 1 }}>
        <div
          style={{
            borderRadius: 28,
            background: "#0f1116",
            border: "2px solid #ffffff1c",
            boxShadow: "0 50px 120px #000000aa",
            overflow: "hidden",
          }}
        >
          <div style={{ display: "flex", gap: 10, padding: "20px 24px", background: "#171a21" }}>
            {["#ff5f57", "#febc2e", "#28c840"].map((c) => (
              <div key={c} style={{ width: 14, height: 14, borderRadius: 14, background: c }} />
            ))}
            <div style={{ marginLeft: 16, fontFamily: sans, fontSize: 20, color: muted }}>
              infra/azure/main.tf
            </div>
          </div>
          <pre
            style={{
              margin: 0,
              padding: "30px 36px",
              minHeight: 430,
              fontFamily: "Consolas, 'Courier New', monospace",
              fontSize: 29,
              lineHeight: 1.5,
              color: "#d8dbe2",
              whiteSpace: "pre-wrap",
            }}
          >
            {visible.split(/("[^"\n]*"?)/).map((part, i) =>
              part.startsWith('"') ? (
                <span key={i} style={{ color: goldSoft }}>
                  {part}
                </span>
              ) : (
                <span key={i}>{part}</span>
              ),
            )}
            <span style={{ color: gold, opacity: Math.floor(frame / 15) % 2 }}>▍</span>
          </pre>
        </div>
      </Rise>
    </AbsoluteFill>
  );
};

const Counter: React.FC<{ value: number; label: string; delay: number }> = ({
  value,
  label,
  delay,
}) => {
  const frame = useCurrentFrame();
  const n = Math.round(
    interpolate(frame, [delay, delay + 40], [0, value], { ...clamp, easing: ease }),
  );
  const rise = useRise(delay, 30);
  return (
    <div style={{ ...rise, flex: 1 }}>
      <div style={{ fontFamily: sans, fontWeight: 700, fontSize: 120, lineHeight: 1, color: gold, letterSpacing: -2 }}>
        {n.toLocaleString("fr-CA")}
      </div>
      <div style={{ fontFamily: sans, fontSize: 30, color: text, marginTop: 10, lineHeight: 1.3 }}>
        {label}
      </div>
    </div>
  );
};

const pipeline = ["Format", "Analyse", "Tests", "Build", "Playwright", "Déploiement"];

const Quality: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ padding: "100px 120px", justifyContent: "center" }}>
      <Eyebrow>Qualité et CI/CD</Eyebrow>
      <Heading>Testé à chaque modification, et chaque nuit.</Heading>
      <div style={{ display: "flex", gap: 60, marginTop: 60 }}>
        <Counter value={72} label="tests Flutter (unitaires et widgets)" delay={14} />
        <Counter value={61} label="tests Playwright (écrans, API, sécurité)" delay={22} />
        <Counter value={3} label="machines en parallèle, Chromium et WebKit" delay={30} />
      </div>
      <div style={{ display: "flex", alignItems: "center", marginTop: 70 }}>
        {pipeline.map((p, i) => {
          const on = interpolate(frame, [50 + i * 8, 58 + i * 8], [0, 1], clamp);
          return (
            <React.Fragment key={p}>
              <div
                style={{
                  fontFamily: sans,
                  fontWeight: 700,
                  fontSize: 27,
                  padding: "16px 26px",
                  borderRadius: 18,
                  color: on > 0.5 ? ink : muted,
                  background: on > 0.5 ? gold : "#ffffff0d",
                  border: `2px solid ${on > 0.5 ? gold : "#ffffff22"}`,
                  opacity: 0.4 + 0.6 * on,
                }}
              >
                {on > 0.5 ? "✓ " : ""}
                {p}
              </div>
              {i < pipeline.length - 1 ? (
                <div style={{ width: 46, height: 3, background: on > 0.5 ? gold : "#ffffff22" }} />
              ) : null}
            </React.Fragment>
          );
        })}
      </div>
      <div style={{ display: "flex", gap: 18, marginTop: 44, flexWrap: "wrap" }}>
        <Chip label="Accessibilité WCAG 2 AA (axe-core)" delay={100} />
        <Chip label="CodeQL" delay={104} />
        <Chip label="Dependabot" delay={108} />
        <Chip label="Agents IA pour les tests" delay={112} />
      </div>
    </AbsoluteFill>
  );
};

const Numbers: React.FC = () => (
  <AbsoluteFill style={{ padding: "0 140px", justifyContent: "center" }}>
    <Eyebrow>En chiffres</Eyebrow>
    <div style={{ display: "flex", gap: 50, marginTop: 50 }}>
      <Counter value={121} label="commits depuis octobre 2026" delay={6} />
      <Counter value={20000} label="lignes de Dart, environ" delay={12} />
      <Counter value={2} label="langues, français et anglais" delay={18} />
      <Counter value={1} label="développeur" delay={24} />
    </div>
  </AbsoluteFill>
);

const Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const glow = 0.5 + 0.5 * Math.sin(frame / 12);
  return (
    <AbsoluteFill style={{ alignItems: "center", justifyContent: "center", textAlign: "center" }}>
      <Rise>
        <Img
          src={staticFile("app/logo.png")}
          style={{ width: 120, height: 120, borderRadius: 28, boxShadow: `0 20px ${60 + 30 * glow}px ${gold}66` }}
        />
      </Rise>
      <Heading size={120} delay={6}>
        Ride with Yan
      </Heading>
      <Rise delay={14} style={{ marginTop: 8 }}>
        <div style={{ fontFamily: serifItalic, fontStyle: "italic", fontSize: 54, color: goldSoft }}>
          Yanis Garoui
        </div>
      </Rise>
      <Rise delay={26} style={{ marginTop: 56 }}>
        <div style={{ fontFamily: sans, fontSize: 34, color: text }}>
          Essayer l'app : <span style={{ color: gold }}>yanis312.github.io/ride-with-yan</span>
        </div>
      </Rise>
      <Rise delay={32} style={{ marginTop: 18 }}>
        <div style={{ fontFamily: sans, fontSize: 34, color: text }}>
          Le code : <span style={{ color: gold }}>github.com/Yanis312/ride-with-yan</span>
        </div>
      </Rise>
    </AbsoluteFill>
  );
};

/* ---------------------------------------------------------------- Montage */

const screens = [
  {
    image: "veille-0",
    step: "01 · Écran de veille",
    title: "Bienvenue à bord.",
    lines: ["Une tablette derrière le siège", "Bilingue, mode clair et sombre"],
  },
  {
    image: "veille-2",
    step: "02 · Vitrines",
    title: "La boutique défile toute seule.",
    lines: ["Un rayon hommes, un rayon femmes", "Un geste pour entrer"],
  },
  {
    image: "lounge",
    step: "03 · Lounge",
    title: "Tout le trajet à portée de main.",
    lines: ["Météo et alertes d'Ottawa", "Nouvelles, vidéos, sondage"],
  },
  {
    image: "boutique-femmes",
    step: "04 · Boutique",
    title: "Panier, tailles, stock.",
    lines: ["Prix et stock gérés en direct", "depuis un panneau d'administration"],
  },
  {
    image: "commande-qr",
    step: "05 · Commande",
    title: "Un code QR, et c'est commandé.",
    lines: ["La commande s'écrit seule dans WhatsApp", "Aucune donnée gardée sur la tablette"],
  },
  {
    image: "yan",
    step: "06 · Assistant",
    title: "Yan, l'assistant de bord.",
    lines: ["Il répond en français ou en anglais", "et lit sa réponse à voix haute"],
  },
];

const T = 15; // durée d'une transition, en images
const scenes: { frames: number; node: React.ReactNode }[] = [
  { frames: 150, node: <Intro /> },
  ...screens.map((s) => ({ frames: 120, node: <Screen {...s} /> })),
  { frames: 190, node: <Assistant /> },
  { frames: 190, node: <Stack /> },
  { frames: 170, node: <Infra /> },
  { frames: 210, node: <Quality /> },
  { frames: 120, node: <Numbers /> },
  { frames: 170, node: <Outro /> },
];

export const PRESENTATION_FRAMES =
  scenes.reduce((sum, s) => sum + s.frames, 0) - T * (scenes.length - 1);

export const Presentation: React.FC = () => (
  <AbsoluteFill>
    <Backdrop />
    <TransitionSeries>
      {scenes.flatMap((s, i) => [
        ...(i > 0
          ? [
              <TransitionSeries.Transition
                key={`t${i}`}
                presentation={i >= 2 && i <= 6 ? slide({ direction: "from-right" }) : fade()}
                timing={linearTiming({ durationInFrames: T })}
              />,
            ]
          : []),
        <TransitionSeries.Sequence key={`s${i}`} durationInFrames={s.frames}>
          {s.node}
        </TransitionSeries.Sequence>,
      ])}
    </TransitionSeries>
  </AbsoluteFill>
);
