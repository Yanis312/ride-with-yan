import React, { createContext, useContext } from "react";
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

export type Lang = "fr" | "en";
const LangContext = createContext<Lang>("fr");
/** Texte dans la langue de la vidéo. */
const useT = () => {
  const lang = useContext(LangContext);
  return (fr: string, en: string) => (lang === "fr" ? fr : en);
};

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
          maskImage:
            "radial-gradient(circle at 50% 50%, black 0%, transparent 75%)",
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
  const s = spring({
    frame: frame - delay,
    fps,
    config: { damping: 14, stiffness: 140 },
  });
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
  const t = useT();
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
        style={{
          marginTop: 26,
          height: 4,
          width: 420 * line,
          background: gold,
          borderRadius: 4,
        }}
      />
      <Rise delay={40} style={{ marginTop: 36 }}>
        <div
          style={{
            fontFamily: sans,
            fontSize: 40,
            color: text,
            textAlign: "center",
          }}
        >
          {t(
            "L'app que j'ai conçue et codée seul pour la tablette de ma voiture.",
            "The app I designed and built on my own for the tablet in my car.",
          )}
        </div>
      </Rise>
      <Rise delay={52} style={{ marginTop: 16 }}>
        <div
          style={{
            fontFamily: sans,
            fontSize: 28,
            color: muted,
            letterSpacing: 2,
          }}
        >
          Ottawa–Gatineau · {t("Français / English", "English / French")}
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
  const lang = useContext(LangContext);
  const frame = useCurrentFrame();
  const { fps, durationInFrames } = useVideoConfig();
  const enter = spring({ frame: frame - 4, fps, config: { damping: 200 } });
  const zoom = interpolate(frame, [0, durationInFrames], [1, 1.06]);
  return (
    <AbsoluteFill
      style={{ flexDirection: "row", alignItems: "center", padding: "0 90px" }}
    >
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
        <div
          style={{
            width: "100%",
            height: "100%",
            borderRadius: 26,
            overflow: "hidden",
          }}
        >
          <Img
            src={staticFile(`app/${lang}/${image}.png`)}
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
      <div
        style={{ fontFamily: sans, fontWeight: 700, fontSize: 34, color: text }}
      >
        {title}
      </div>
      <div
        style={{
          fontFamily: sans,
          fontSize: 25,
          color: muted,
          marginTop: 10,
          lineHeight: 1.35,
        }}
      >
        {sub}
      </div>
    </div>
  );
};

const Arrow: React.FC<{ delay: number }> = ({ delay }) => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [delay, delay + 14], [0, 1], {
    ...clamp,
    easing: ease,
  });
  return (
    <div style={{ width: 90, display: "flex", alignItems: "center" }}>
      <div
        style={{ height: 4, width: 70 * p, background: gold, borderRadius: 4 }}
      />
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

const Assistant: React.FC = () => {
  const t = useT();
  return (
    <AbsoluteFill style={{ padding: "110px 120px", justifyContent: "center" }}>
      <Eyebrow>
        {t("Intelligence artificielle", "Artificial intelligence")}
      </Eyebrow>
      <Heading>
        {t(
          "Yan répond aux passagers, à l'écrit et à voix haute.",
          "Yan answers passengers, in text and out loud.",
        )}
      </Heading>
      <div style={{ display: "flex", alignItems: "center", marginTop: 70 }}>
        <Node
          title={t("Tablette", "Tablet")}
          sub={t(
            "Le passager pose sa question",
            "The passenger asks a question",
          )}
          delay={18}
        />
        <Arrow delay={28} />
        <Node
          title={t("Fonction serveur", "Server function")}
          sub="Supabase Edge · TypeScript · quotas"
          delay={32}
        />
        <Arrow delay={42} />
        <Node
          title="Azure AI Foundry"
          sub={t(
            "GPT-4.1-mini, hébergé au Canada",
            "GPT-4.1-mini, hosted in Canada",
          )}
          delay={46}
          accent
        />
      </div>
      <div
        style={{ display: "flex", gap: 20, marginTop: 60, flexWrap: "wrap" }}
      >
        <Chip
          label={t(
            "Azure AI Speech · voix québécoise",
            "Azure AI Speech · natural voices",
          )}
          delay={62}
        />
        <Chip label="Prompt engineering" delay={68} />
        <Chip label={t("Filtres de contenu", "Content filters")} delay={74} />
        <Chip
          label={t("Clé d'API jamais dans l'app", "API key never in the app")}
          delay={80}
        />
      </div>
    </AbsoluteFill>
  );
};

const Stack: React.FC = () => {
  const t = useT();
  const groups: { label: string; items: string[] }[] = [
    {
      label: "App",
      items: ["Flutter", "Dart", "Android", "Web · WebAssembly"],
    },
    {
      label: t("Données", "Data"),
      items: [
        "Supabase",
        "PostgreSQL",
        t("Sécurité par ligne (RLS)", "Row-level security"),
        "Deno · TypeScript",
      ],
    },
    {
      label: t("Cloud et IA", "Cloud & AI"),
      items: [
        "Azure AI Foundry",
        "Azure AI Speech",
        "AI Search · RAG",
        "Sentry",
      ],
    },
    {
      label: "DevOps",
      items: ["Terraform", "Docker", "GitHub Actions", "Azure Pipelines"],
    },
  ];
  return (
    <AbsoluteFill style={{ padding: "100px 120px", justifyContent: "center" }}>
      <Eyebrow>{t("La stack", "The stack")}</Eyebrow>
      <Heading>
        {t(
          "Du code à la production, de bout en bout.",
          "From code to production, end to end.",
        )}
      </Heading>
      <div
        style={{
          marginTop: 60,
          display: "flex",
          flexDirection: "column",
          gap: 26,
        }}
      >
        {groups.map((g, gi) => (
          <div
            key={g.label}
            style={{ display: "flex", alignItems: "center", gap: 20 }}
          >
            <Rise delay={14 + gi * 10} style={{ width: 230 }}>
              <div
                style={{
                  fontFamily: sans,
                  fontWeight: 700,
                  fontSize: 26,
                  color: goldSoft,
                  letterSpacing: 3,
                  textTransform: "uppercase",
                }}
              >
                {g.label}
              </div>
            </Rise>
            {g.items.map((item, i) => (
              <Chip
                key={item}
                label={item}
                delay={18 + gi * 10 + i * 3}
                strong={i === 0}
              />
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
  const t = useT();
  const frame = useCurrentFrame();
  const all = terraform.join("\n");
  const shown = Math.floor(
    interpolate(frame, [16, 110], [0, all.length], clamp),
  );
  const visible = all.slice(0, shown);
  return (
    <AbsoluteFill
      style={{
        flexDirection: "row",
        alignItems: "center",
        padding: "0 120px",
        gap: 80,
      }}
    >
      <div style={{ width: 640 }}>
        <Eyebrow>
          {t("Infrastructure en code", "Infrastructure as code")}
        </Eyebrow>
        <Heading size={84}>
          {t(
            "Terraform crée tout Azure, sans un clic.",
            "Terraform builds all of Azure, no clicking.",
          )}
        </Heading>
        <Rise delay={22} style={{ marginTop: 34 }}>
          <div
            style={{
              fontFamily: sans,
              fontSize: 30,
              color: muted,
              lineHeight: 1.45,
            }}
          >
            {t(
              "Foundry, le modèle de Yan, la voix, AI Search et les services d'IA : tout est décrit, relu et recréable en une commande.",
              "Foundry, Yan's model, the voice, AI Search and the AI services: all described, reviewed and rebuilt with one command.",
            )}
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
          <div
            style={{
              display: "flex",
              gap: 10,
              padding: "20px 24px",
              background: "#171a21",
            }}
          >
            {["#ff5f57", "#febc2e", "#28c840"].map((c) => (
              <div
                key={c}
                style={{
                  width: 14,
                  height: 14,
                  borderRadius: 14,
                  background: c,
                }}
              />
            ))}
            <div
              style={{
                marginLeft: 16,
                fontFamily: sans,
                fontSize: 20,
                color: muted,
              }}
            >
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
            <span style={{ color: gold, opacity: Math.floor(frame / 15) % 2 }}>
              ▍
            </span>
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
  const lang = useContext(LangContext);
  const frame = useCurrentFrame();
  const n = Math.round(
    interpolate(frame, [delay, delay + 40], [0, value], {
      ...clamp,
      easing: ease,
    }),
  );
  const rise = useRise(delay, 30);
  return (
    <div style={{ ...rise, flex: 1 }}>
      <div
        style={{
          fontFamily: sans,
          fontWeight: 700,
          fontSize: 120,
          lineHeight: 1,
          color: gold,
          letterSpacing: -2,
        }}
      >
        {n.toLocaleString(lang === "fr" ? "fr-CA" : "en-CA")}
      </div>
      <div
        style={{
          fontFamily: sans,
          fontSize: 30,
          color: text,
          marginTop: 10,
          lineHeight: 1.3,
        }}
      >
        {label}
      </div>
    </div>
  );
};

const Quality: React.FC = () => {
  const t = useT();
  const pipeline = [
    "Format",
    t("Analyse", "Analyze"),
    "Tests",
    "Build",
    "Playwright",
    t("Déploiement", "Deploy"),
  ];
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ padding: "100px 120px", justifyContent: "center" }}>
      <Eyebrow>{t("Qualité et CI/CD", "Quality & CI/CD")}</Eyebrow>
      <Heading>
        {t(
          "Testé à chaque modification, et chaque nuit.",
          "Tested on every change, and every night.",
        )}
      </Heading>
      <div style={{ display: "flex", gap: 60, marginTop: 60 }}>
        <Counter
          value={72}
          label={t(
            "tests Flutter (unitaires et widgets)",
            "Flutter tests (unit and widget)",
          )}
          delay={14}
        />
        <Counter
          value={61}
          label={t(
            "tests Playwright (écrans, API, sécurité)",
            "Playwright tests (UI, API, security)",
          )}
          delay={22}
        />
        <Counter
          value={3}
          label={t(
            "machines en parallèle, Chromium et WebKit",
            "parallel machines, Chromium and WebKit",
          )}
          delay={30}
        />
      </div>
      <div style={{ display: "flex", alignItems: "center", marginTop: 70 }}>
        {pipeline.map((p, i) => {
          const on = interpolate(
            frame,
            [50 + i * 8, 58 + i * 8],
            [0, 1],
            clamp,
          );
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
                <div
                  style={{
                    width: 46,
                    height: 3,
                    background: on > 0.5 ? gold : "#ffffff22",
                  }}
                />
              ) : null}
            </React.Fragment>
          );
        })}
      </div>
      <div
        style={{ display: "flex", gap: 18, marginTop: 44, flexWrap: "wrap" }}
      >
        <Chip
          label={t(
            "Accessibilité WCAG 2 AA (axe-core)",
            "WCAG 2 AA accessibility (axe-core)",
          )}
          delay={100}
        />
        <Chip label="CodeQL" delay={104} />
        <Chip label="Dependabot" delay={108} />
        <Chip
          label={t("Agents IA pour les tests", "AI agents for testing")}
          delay={112}
        />
      </div>
    </AbsoluteFill>
  );
};

const Numbers: React.FC = () => {
  const t = useT();
  return (
    <AbsoluteFill style={{ padding: "0 140px", justifyContent: "center" }}>
      <Eyebrow>{t("En chiffres", "By the numbers")}</Eyebrow>
      <div style={{ display: "flex", gap: 50, marginTop: 50 }}>
        <Counter
          value={121}
          label={t("commits depuis octobre 2026", "commits since October 2026")}
          delay={6}
        />
        <Counter
          value={20000}
          label={t("lignes de Dart, environ", "lines of Dart, roughly")}
          delay={12}
        />
        <Counter
          value={2}
          label={t(
            "langues, français et anglais",
            "languages, English and French",
          )}
          delay={18}
        />
        <Counter value={1} label={t("développeur", "developer")} delay={24} />
      </div>
    </AbsoluteFill>
  );
};

const Outro: React.FC = () => {
  const t = useT();
  const frame = useCurrentFrame();
  const glow = 0.5 + 0.5 * Math.sin(frame / 12);
  return (
    <AbsoluteFill
      style={{
        alignItems: "center",
        justifyContent: "center",
        textAlign: "center",
      }}
    >
      <Rise>
        <Img
          src={staticFile("app/logo.png")}
          style={{
            width: 120,
            height: 120,
            borderRadius: 28,
            boxShadow: `0 20px ${60 + 30 * glow}px ${gold}66`,
          }}
        />
      </Rise>
      <Heading size={120} delay={6}>
        Ride with Yan
      </Heading>
      <Rise delay={14} style={{ marginTop: 8 }}>
        <div
          style={{
            fontFamily: serifItalic,
            fontStyle: "italic",
            fontSize: 54,
            color: goldSoft,
          }}
        >
          Yanis Garoui
        </div>
      </Rise>
      <Rise delay={26} style={{ marginTop: 56 }}>
        <div style={{ fontFamily: sans, fontSize: 34, color: text }}>
          {t("Essayer l'app : ", "Try the app: ")}
          <span style={{ color: gold }}>yanis312.github.io/ride-with-yan</span>
        </div>
      </Rise>
    </AbsoluteFill>
  );
};

/* ---------------------------------------------------------------- Montage */

const screensFor = (t: (fr: string, en: string) => string) => [
  {
    image: "veille-0",
    step: t("01 · Écran de veille", "01 · Idle screen"),
    title: t("Bienvenue à bord.", "Welcome aboard."),
    lines: [
      t("Une tablette derrière le siège", "A tablet behind the seat"),
      t("Bilingue, mode clair et sombre", "Bilingual, light and dark mode"),
    ],
  },
  {
    image: "veille-2",
    step: t("02 · Vitrines", "02 · Showcases"),
    title: t("La boutique défile toute seule.", "The shop scrolls by itself."),
    lines: [
      t("Un rayon hommes, un rayon femmes", "A men's shop and a women's shop"),
      t("Un geste pour entrer", "One tap to step in"),
    ],
  },
  {
    image: "lounge",
    step: t("03 · Lounge", "03 · Lounge"),
    title: t("Tout le trajet à portée de main.", "The whole ride at hand."),
    lines: [
      t("Météo et alertes d'Ottawa", "Ottawa weather and alerts"),
      t("Nouvelles, vidéos, sondage", "News, videos, poll"),
    ],
  },
  {
    image: "boutique-femmes",
    step: t("04 · Boutique", "04 · Shop"),
    title: t("Panier, tailles, stock.", "Cart, sizes, stock."),
    lines: [
      t("Prix et stock gérés en direct", "Prices and stock managed live"),
      t("depuis un panneau d'administration", "from an admin panel"),
    ],
  },
  {
    image: "commande-qr",
    step: t("05 · Commande", "05 · Ordering"),
    title: t(
      "Un code QR, et c'est commandé.",
      "One QR code, and it's ordered.",
    ),
    lines: [
      t(
        "La commande s'écrit seule dans WhatsApp",
        "The order writes itself in WhatsApp",
      ),
      t("Aucune donnée gardée sur la tablette", "No data kept on the tablet"),
    ],
  },
  {
    image: "yan",
    step: t("06 · Assistant", "06 · Assistant"),
    title: t("Yan, l'assistant de bord.", "Yan, the onboard assistant."),
    lines: [
      t("Il répond en français ou en anglais", "Answers in English or French"),
      t("et lit sa réponse à voix haute", "and reads the answer out loud"),
    ],
  },
];

const T = 15; // durée d'une transition, en images
const sceneFrames = [
  150, 120, 120, 120, 120, 120, 120, 190, 190, 170, 210, 120, 170,
];

export const PRESENTATION_FRAMES =
  sceneFrames.reduce((sum, f) => sum + f, 0) - T * (sceneFrames.length - 1);

const Scenes: React.FC = () => {
  const t = useT();
  const nodes: React.ReactNode[] = [
    <Intro key="intro" />,
    ...screensFor(t).map((s) => <Screen key={s.image} {...s} />),
    <Assistant key="ai" />,
    <Stack key="stack" />,
    <Infra key="infra" />,
    <Quality key="quality" />,
    <Numbers key="numbers" />,
    <Outro key="outro" />,
  ];
  return (
    <TransitionSeries>
      {nodes.flatMap((node, i) => [
        ...(i > 0
          ? [
              <TransitionSeries.Transition
                key={`t${i}`}
                presentation={
                  i >= 2 && i <= 6 ? slide({ direction: "from-right" }) : fade()
                }
                timing={linearTiming({ durationInFrames: T })}
              />,
            ]
          : []),
        <TransitionSeries.Sequence
          key={`s${i}`}
          durationInFrames={sceneFrames[i]}
        >
          {node}
        </TransitionSeries.Sequence>,
      ])}
    </TransitionSeries>
  );
};

export const Presentation: React.FC<{ lang: Lang }> = ({ lang }) => (
  <LangContext.Provider value={lang}>
    <AbsoluteFill>
      <Backdrop />
      <Scenes />
    </AbsoluteFill>
  </LangContext.Provider>
);
