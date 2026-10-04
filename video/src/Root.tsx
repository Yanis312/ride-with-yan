import React from "react";
import { Composition } from "remotion";
import { Reel, ReelProps, REEL_FRAMES } from "./Reel";

/** Un reel par site de démonstration de la section Collaborations. */
const reels: ReelProps[] = [
  {
    slug: "mokka",
    title: "Maison Mokka",
    kind: "Café · Boulangerie",
    accent: "#C98A4B",
    desktopHeight: 2436,
    mobileHeight: 8048,
    chips: ["Design unique", "Menu en ligne", "SEO Google"],
  },
  {
    slug: "atelier-nord",
    title: "Atelier Nord",
    kind: "Mode · Boutique",
    accent: "#D2552B",
    desktopHeight: 2187,
    mobileHeight: 8778,
    chips: ["Design unique", "Boutique en ligne", "Paiement"],
  },
  {
    slug: "noir-tailor",
    title: "Noir Tailor",
    kind: "Luxe · Sur mesure",
    accent: "#C9A36A",
    desktopHeight: 1260,
    mobileHeight: 3788,
    chips: ["Design unique", "Rendez-vous", "SEO Google"],
  },
  {
    slug: "vlt-active",
    title: "VLT Active",
    kind: "Sport · E-commerce",
    accent: "#D4FF3A",
    desktopHeight: 1537,
    mobileHeight: 4446,
    chips: ["Design unique", "Boutique en ligne", "Rapide"],
  },
];

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {reels.map((reel) => (
        <Composition
          key={reel.slug}
          id={reel.slug}
          component={Reel}
          durationInFrames={REEL_FRAMES}
          fps={30}
          width={1280}
          height={720}
          defaultProps={reel}
        />
      ))}
    </>
  );
};
