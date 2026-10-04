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
import { loadFont as loadSerif } from "@remotion/google-fonts/CormorantGaramond";
import { loadFont as loadSans } from "@remotion/google-fonts/PlusJakartaSans";

const serif = loadSerif("normal", { weights: ["500", "600"] }).fontFamily;
const sans = loadSans("normal", { weights: ["500", "700"] }).fontFamily;

export type ReelProps = {
  slug: string;
  title: string;
  kind: string;
  accent: string;
  /** Hauteur des captures pleine page (largeur 1440 et 780). */
  desktopHeight: number;
  mobileHeight: number;
  chips: [string, string, string];
};

export const REEL_FRAMES = 390;

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;
const inOut = Easing.inOut(Easing.cubic);

/** Fond sombre : halo de la couleur du site qui dérive, et fine grille. */
const Backdrop: React.FC<{ accent: string }> = ({ accent }) => {
  const frame = useCurrentFrame();
  const x = 30 + 40 * Math.sin(frame / 90);
  const y = 35 + 20 * Math.cos(frame / 120);
  return (
    <AbsoluteFill style={{ backgroundColor: "#09090c" }}>
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle at ${x}% ${y}%, ${accent}66 0%, transparent 46%), radial-gradient(circle at ${100 - x}% ${90 - y}%, ${accent}2e 0%, transparent 50%)`,
        }}
      />
      <AbsoluteFill
        style={{
          backgroundImage:
            "linear-gradient(#ffffff0a 1px, transparent 1px), linear-gradient(90deg, #ffffff0a 1px, transparent 1px)",
          backgroundSize: "64px 64px",
          maskImage:
            "radial-gradient(circle at 50% 50%, black 0%, transparent 75%)",
        }}
      />
    </AbsoluteFill>
  );
};

/** Titre d'ouverture : les lettres montent une à une. */
const Title: React.FC<{ title: string; kind: string; accent: string }> = ({
  title,
  kind,
  accent,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const out = interpolate(frame, [58, 76], [0, 1], { ...clamp, easing: inOut });
  const line = interpolate(frame, [8, 40], [0, 1], { ...clamp, easing: inOut });

  return (
    <AbsoluteFill
      style={{
        alignItems: "center",
        justifyContent: "center",
        opacity: 1 - out,
        transform: `translateY(${-60 * out}px) scale(${1 + 0.06 * out})`,
      }}
    >
      <div
        style={{
          fontFamily: sans,
          fontWeight: 700,
          fontSize: 20,
          letterSpacing: 8,
          textTransform: "uppercase",
          color: accent,
          opacity: interpolate(frame, [4, 22], [0, 1], clamp),
        }}
      >
        {kind}
      </div>
      <div style={{ display: "flex", marginTop: 10 }}>
        {title.split("").map((char, i) => {
          const s = spring({
            frame: frame - 6 - i * 2,
            fps,
            config: { damping: 14, stiffness: 120 },
          });
          return (
            <span
              key={i}
              style={{
                fontFamily: serif,
                fontWeight: 600,
                fontSize: 150,
                lineHeight: 1,
                color: "#fff6ec",
                display: "inline-block",
                whiteSpace: "pre",
                opacity: s,
                transform: `translateY(${(1 - s) * 90}px)`,
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
          height: 3,
          width: 360 * line,
          background: accent,
          borderRadius: 3,
        }}
      />
    </AbsoluteFill>
  );
};

/** Fenêtre de navigateur dont la page défile. */
const Browser: React.FC<{
  slug: string;
  pageHeight: number;
  scroll: number;
}> = ({ slug, pageHeight, scroll }) => {
  const width = 860;
  const view = 500;
  const scale = width / 1440;
  const travel = Math.max(0, pageHeight * scale - view);
  return (
    <div
      style={{
        width,
        borderRadius: 18,
        overflow: "hidden",
        boxShadow: "0 60px 120px #000000aa, 0 0 0 1px #ffffff1f",
        background: "#15161b",
      }}
    >
      <div
        style={{
          height: 38,
          display: "flex",
          alignItems: "center",
          gap: 8,
          padding: "0 16px",
          background: "#1b1d23",
        }}
      >
        {["#ff5f57", "#febc2e", "#28c840"].map((c) => (
          <div
            key={c}
            style={{ width: 11, height: 11, borderRadius: 11, background: c }}
          />
        ))}
        <div
          style={{
            marginLeft: 18,
            flex: 1,
            height: 22,
            borderRadius: 7,
            background: "#2a2d35",
            color: "#b4b8c2",
            fontFamily: sans,
            fontSize: 12,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          {slug.replace("-", "")}.demo
        </div>
        <div style={{ width: 60 }} />
      </div>
      <div style={{ height: view, overflow: "hidden" }}>
        <Img
          src={staticFile(`${slug}-desktop.jpg`)}
          style={{
            width,
            display: "block",
            transform: `translateY(${-travel * scroll}px)`,
          }}
        />
      </div>
    </div>
  );
};

/** Téléphone dont la page mobile défile. */
const Phone: React.FC<{
  slug: string;
  pageHeight: number;
  scroll: number;
}> = ({ slug, pageHeight, scroll }) => {
  const width = 250;
  const view = 520;
  const scale = width / 780;
  // On ne parcourt que le haut de la page : un défilement lisible.
  const travel = Math.min(pageHeight * scale - view, 1500);
  return (
    <div
      style={{
        padding: 9,
        borderRadius: 40,
        background: "#0b0c10",
        boxShadow: "0 50px 110px #000000cc, 0 0 0 1.5px #ffffff2e",
      }}
    >
      <div
        style={{
          width,
          height: view,
          borderRadius: 32,
          overflow: "hidden",
          position: "relative",
        }}
      >
        <Img
          src={staticFile(`${slug}-mobile.jpg`)}
          style={{
            width,
            display: "block",
            transform: `translateY(${-travel * scroll}px)`,
          }}
        />
        <div
          style={{
            position: "absolute",
            top: 8,
            left: "50%",
            width: 70,
            height: 18,
            marginLeft: -35,
            borderRadius: 18,
            background: "#0b0c10",
          }}
        />
      </div>
    </div>
  );
};

/** Pastille qui surgit à côté de la fenêtre. */
const Chip: React.FC<{
  label: string;
  at: number;
  until: number;
  x: number;
  y: number;
  accent: string;
}> = ({ label, at, until, x, y, accent }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = spring({
    frame: frame - at,
    fps,
    config: { damping: 11, stiffness: 140 },
  });
  const out = interpolate(frame, [until, until + 12], [0, 1], clamp);
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        opacity: s * (1 - out),
        transform: `scale(${0.6 + 0.4 * s}) translateY(${(1 - s) * 24 + Math.sin(frame / 22 + x) * 4}px)`,
        padding: "13px 22px",
        borderRadius: 999,
        background: "#0e0f14e6",
        border: `1.5px solid ${accent}`,
        boxShadow: `0 0 34px ${accent}66`,
        color: "#fff6ec",
        fontFamily: sans,
        fontWeight: 700,
        fontSize: 21,
        display: "flex",
        alignItems: "center",
        gap: 10,
      }}
    >
      <div
        style={{ width: 10, height: 10, borderRadius: 10, background: accent }}
      />
      {label}
    </div>
  );
};

export const Reel: React.FC<ReelProps> = ({
  slug,
  title,
  kind,
  accent,
  desktopHeight,
  mobileHeight,
  chips,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fenêtre : entre en biais, puis recule quand le téléphone arrive.
  const enter = spring({
    frame: frame - 56,
    fps,
    config: { damping: 16, stiffness: 70 },
  });
  const aside = interpolate(frame, [222, 262], [0, 1], {
    ...clamp,
    easing: inOut,
  });
  const desktopScroll = interpolate(frame, [92, 150, 170, 226], [0, 0.5, 0.5, 1], {
    ...clamp,
    easing: inOut,
  });
  const drift = Math.sin(frame / 40) * 1.2;

  // Téléphone : glisse depuis la droite.
  const phoneIn = spring({
    frame: frame - 226,
    fps,
    config: { damping: 15, stiffness: 80 },
  });
  const mobileScroll = interpolate(frame, [250, 345], [0, 1], {
    ...clamp,
    easing: inOut,
  });

  // Fin : tout s'éteint pour que la boucle reparte proprement.
  const end = interpolate(frame, [REEL_FRAMES - 22, REEL_FRAMES - 4], [0, 1], {
    ...clamp,
    easing: inOut,
  });

  return (
    <AbsoluteFill>
      <Backdrop accent={accent} />
      <Title title={title} kind={kind} accent={accent} />

      <AbsoluteFill style={{ perspective: 1600, opacity: 1 - end }}>
        <div
          style={{
            position: "absolute",
            left: 210 - 150 * aside,
            top: 96,
            opacity: enter,
            filter: `blur(${2.5 * aside}px) brightness(${1 - 0.25 * aside})`,
            transform: `translateY(${(1 - enter) * 420}px) rotateX(${
              20 - 13 * enter
            }deg) rotateY(${-22 + 12 * enter + drift + 9 * aside}deg) scale(${
              0.86 + 0.14 * enter - 0.1 * aside
            })`,
            transformOrigin: "50% 60%",
          }}
        >
          <Browser slug={slug} pageHeight={desktopHeight} scroll={desktopScroll} />
        </div>

        <div
          style={{
            position: "absolute",
            left: 850,
            top: 86,
            opacity: phoneIn,
            transform: `translateX(${(1 - phoneIn) * 520}px) rotateY(${
              28 - 40 * phoneIn - drift
            }deg) rotateZ(${4 - 4 * phoneIn}deg)`,
          }}
        >
          <Phone slug={slug} pageHeight={mobileHeight} scroll={mobileScroll} />
        </div>
      </AbsoluteFill>

      <AbsoluteFill style={{ opacity: 1 - end }}>
        <Chip label={chips[0]} at={104} until={214} x={70} y={130} accent={accent} />
        <Chip label={chips[1]} at={140} until={214} x={950} y={250} accent={accent} />
        <Chip label={chips[2]} at={176} until={214} x={120} y={560} accent={accent} />
        <Chip label="Mobile" at={262} until={352} x={600} y={590} accent={accent} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
