/**
 * Topic slug -> lucide icon.
 *
 * The backend stores an EMOJI in `Topic.icon` ("✈️", "🍳", "🇰🇷") because the
 * Flutter app paints it into a coloured circle where an emoji reads as
 * decoration. On the web the same string lands in a `<span>` next to Inter at
 * 14px and renders at whatever size and colour the viewer's OS font decides —
 * which is why the old /topics page looked like a different product from the
 * rest of the site, and why a flag emoji stood in for a music genre.
 *
 * So the web maps the slug to a lucide glyph instead: one stroke weight, one
 * colour, one size, the same icon set as every other surface. The map covers
 * the full seed list in the backend's `models/Topic.js` (`seedDefaults`) plus
 * the older short slugs still stored on some profiles ("food", "reading",
 * "sports"); anything unknown falls back to `Hash`, which is exactly what the
 * Topics tab already uses as its own icon in the community sub-nav.
 *
 * Only the ICON is dropped — `Topic.name` is still the backend's (localized)
 * string, and the emoji may still be shown as decorative aria-hidden text by a
 * caller that wants it.
 */
import React from "react";
import {
  Apple,
  Backpack,
  Baby,
  BarChart3,
  Bed,
  Beer,
  Bike,
  Bird,
  BookOpen,
  Brain,
  Briefcase,
  Brush,
  Building2,
  Cake,
  Camera,
  Car,
  Cat,
  ChefHat,
  Clapperboard,
  Code,
  Coffee,
  CupSoda,
  Disc3,
  Dog,
  Drama,
  Droplet,
  Dumbbell,
  Feather,
  Fish,
  Flower2,
  Footprints,
  Gamepad2,
  GraduationCap,
  Guitar,
  Hammer,
  HandHeart,
  Handshake,
  Hash,
  Headphones,
  Heart,
  Home,
  Landmark,
  Laptop,
  Laugh,
  Languages,
  Leaf,
  Lightbulb,
  Mic,
  Microscope,
  Moon,
  Mountain,
  Music,
  Newspaper,
  Palette,
  PawPrint,
  PenLine,
  PersonStanding,
  Piano,
  Plane,
  Popcorn,
  Rabbit,
  Radio,
  Rocket,
  Salad,
  Sandwich,
  ScrollText,
  Shirt,
  ShoppingBag,
  Snowflake,
  Sparkles,
  Sprout,
  Sun,
  Swords,
  Tent,
  Ticket,
  TrendingUp,
  Trophy,
  Tv,
  Umbrella,
  Users,
  Utensils,
  Volleyball,
  Wallet,
  Waves,
  Wine,
} from "lucide-react";

/** What every lucide icon component accepts here. */
export type TopicIcon = React.ComponentType<{
  size?: number | string;
  className?: string;
  strokeWidth?: number;
  "aria-hidden"?: boolean | "true" | "false";
}>;

const ICONS: { [slug: string]: TopicIcon } = {
  // Food & drink
  eating_out: Utensils,
  cooking: ChefHat,
  drinking: Beer,
  coffee: Coffee,
  tea: CupSoda,
  baking: Cake,
  wine: Wine,
  vegetarian: Salad,
  desserts: Cake,
  street_food: Sandwich,
  food: Utensils,
  nutrition: Apple,

  // Travel
  travel: Plane,
  backpacking: Backpack,
  road_trips: Car,
  beaches: Umbrella,
  mountains: Mountain,
  camping: Tent,
  city_trips: Building2,
  culture_travel: Landmark,
  culture: Landmark,

  // Sports & fitness
  gym: Dumbbell,
  fitness: Dumbbell,
  running: Footprints,
  yoga: PersonStanding,
  swimming: Waves,
  football: Volleyball,
  basketball: Volleyball,
  tennis: Volleyball,
  sports: Trophy,
  hiking: Mountain,
  cycling: Bike,
  dancing: Music,
  martial_arts: Swords,
  skiing: Snowflake,

  // Entertainment
  movies: Clapperboard,
  tv_shows: Tv,
  music: Music,
  concerts: Mic,
  gaming: Gamepad2,
  anime: Tv,
  manga: BookOpen,
  kpop: Mic,
  kdrama: Drama,
  netflix: Popcorn,
  podcasts: Headphones,
  comedy: Laugh,

  // Arts & culture
  art: Palette,
  photography: Camera,
  books: BookOpen,
  reading: BookOpen,
  writing: PenLine,
  poetry: Feather,
  museums: Landmark,
  theater: Ticket,
  history: ScrollText,
  design: Brush,

  // Lifestyle
  fashion: Shirt,
  beauty: Sparkles,
  shopping: ShoppingBag,
  skincare: Droplet,
  home_decor: Home,
  gardening: Sprout,
  diy: Hammer,
  minimalism: Sparkles,

  // Pets & nature
  dogs: Dog,
  cats: Cat,
  pets: PawPrint,
  nature: Leaf,
  animals: Rabbit,
  birds: Bird,
  aquarium: Fish,

  // Learning & career
  language_exchange: Languages,
  languages: Languages,
  language_tips: Lightbulb,
  study_abroad: GraduationCap,
  career: Briefcase,
  technology: Laptop,
  programming: Code,
  business: BarChart3,
  startups: Rocket,
  science: Microscope,
  finance: Wallet,

  // Social
  daily_life: Sun,
  making_friends: Handshake,
  relationships: Heart,
  family: Users,
  parenting: Baby,
  news: Newspaper,
  politics: Landmark,
  volunteering: HandHeart,
  nightlife: Moon,

  // Health & wellness
  mental_health: Brain,
  meditation: PersonStanding,
  wellness: Flower2,
  self_improvement: TrendingUp,
  sleep: Bed,

  // Music
  guitar: Guitar,
  piano: Piano,
  singing: Mic,
  djing: Disc3,
  classical_music: Music,
  rock: Guitar,
  hiphop: Mic,
  electronic: Radio,
};

/**
 * The icon for a topic, by slug and then by name.
 *
 * Matching the name as well is not belt-and-braces: `getTopics` answers with
 * the LOCALIZED name, but the seed data's English names are the slugs with
 * spaces ("Street Food" -> street_food), so an English viewer whose profile
 * carries a legacy free-text topic still gets a real glyph.
 */
export const topicIcon = (slug?: string, name?: string): TopicIcon => {
  const candidates = [slug, name];
  for (let i = 0; i < candidates.length; i += 1) {
    const candidate = candidates[i];
    if (!candidate) continue;
    const key = String(candidate).trim().toLowerCase();
    if (ICONS[key]) return ICONS[key];
    const underscored = key.replace(/[\s-]+/g, "_");
    if (ICONS[underscored]) return ICONS[underscored];
  }
  return Hash;
};

export default topicIcon;
