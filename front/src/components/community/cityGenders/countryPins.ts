/**
 * The City tab's countries: the app's 30 pins, same order, same English
 * names (bananatalk_app/lib/pages/community/tabs/city_tab.dart _countryPins).
 * The backend matches `country` by every spelling of the country (toIso2),
 * so the English name is the right thing to send in every locale; the label
 * shown is localized with Intl.DisplayNames where the browser has it.
 */
export const COUNTRY_PINS: Array<{ name: string; flag: string; iso: string }> = [
  { name: "South Korea", flag: "🇰🇷", iso: "KR" },
  { name: "Japan", flag: "🇯🇵", iso: "JP" },
  { name: "United States", flag: "🇺🇸", iso: "US" },
  { name: "China", flag: "🇨🇳", iso: "CN" },
  { name: "United Kingdom", flag: "🇬🇧", iso: "GB" },
  { name: "Germany", flag: "🇩🇪", iso: "DE" },
  { name: "France", flag: "🇫🇷", iso: "FR" },
  { name: "Spain", flag: "🇪🇸", iso: "ES" },
  { name: "Brazil", flag: "🇧🇷", iso: "BR" },
  { name: "India", flag: "🇮🇳", iso: "IN" },
  { name: "Russia", flag: "🇷🇺", iso: "RU" },
  { name: "Turkey", flag: "🇹🇷", iso: "TR" },
  { name: "Indonesia", flag: "🇮🇩", iso: "ID" },
  { name: "Thailand", flag: "🇹🇭", iso: "TH" },
  { name: "Vietnam", flag: "🇻🇳", iso: "VN" },
  { name: "Philippines", flag: "🇵🇭", iso: "PH" },
  { name: "Mexico", flag: "🇲🇽", iso: "MX" },
  { name: "Italy", flag: "🇮🇹", iso: "IT" },
  { name: "Canada", flag: "🇨🇦", iso: "CA" },
  { name: "Australia", flag: "🇦🇺", iso: "AU" },
  { name: "Uzbekistan", flag: "🇺🇿", iso: "UZ" },
  { name: "Taiwan", flag: "🇹🇼", iso: "TW" },
  { name: "Malaysia", flag: "🇲🇾", iso: "MY" },
  { name: "Saudi Arabia", flag: "🇸🇦", iso: "SA" },
  { name: "Egypt", flag: "🇪🇬", iso: "EG" },
  { name: "Argentina", flag: "🇦🇷", iso: "AR" },
  { name: "Colombia", flag: "🇨🇴", iso: "CO" },
  { name: "Nigeria", flag: "🇳🇬", iso: "NG" },
  { name: "Pakistan", flag: "🇵🇰", iso: "PK" },
  { name: "Bangladesh", flag: "🇧🇩", iso: "BD" },
];

export function countryLabel(pin: { name: string; iso: string }, language: string): string {
  try {
    const DN = (Intl as any).DisplayNames;
    if (DN) return new DN([language], { type: "region" }).of(pin.iso) || pin.name;
  } catch (e) {
    // Old browsers / unknown locale: the English name is still correct.
  }
  return pin.name;
}
