#!/usr/bin/env node
/* eslint-disable */
// Inject communityDetail.suggested.{title,seeAll} into every locale file.
const fs = require("fs");
const path = require("path");

const localesDir = path.resolve(__dirname, "..", "src", "utils", "locales");

const TRANSLATIONS = {
  kor: { title: "{{name}}님과 비슷한 멤버", seeAll: "모든 멤버 보기" },
  ja: { title: "{{name}}さんと似たメンバー", seeAll: "すべてのメンバーを見る" },
  zho: { title: "更多像 {{name}} 这样的成员", seeAll: "查看全部成员" },
  zh_TW: { title: "更多像 {{name}} 這樣的成員", seeAll: "查看全部成員" },
  ar: { title: "أعضاء آخرون مثل {{name}}", seeAll: "عرض كل الأعضاء" },
  de: { title: "Mehr Mitglieder wie {{name}}", seeAll: "Alle Mitglieder anzeigen" },
  es: { title: "Más miembros como {{name}}", seeAll: "Ver todos los miembros" },
  fr: { title: "Plus de membres comme {{name}}", seeAll: "Voir tous les membres" },
  hi: { title: "{{name}} जैसे और सदस्य", seeAll: "सभी सदस्य देखें" },
  id: { title: "Lebih banyak anggota seperti {{name}}", seeAll: "Lihat semua anggota" },
  it: { title: "Altri membri come {{name}}", seeAll: "Vedi tutti i membri" },
  pt: { title: "Mais membros como {{name}}", seeAll: "Ver todos os membros" },
  ru: { title: "Другие участники, похожие на {{name}}", seeAll: "Посмотреть всех" },
  th: { title: "สมาชิกอื่นๆ ที่คล้ายกับ {{name}}", seeAll: "ดูสมาชิกทั้งหมด" },
  tl: { title: "Mga miyembrong katulad ni {{name}}", seeAll: "Tingnan lahat ng miyembro" },
  tr: { title: "{{name}} gibi diğer üyeler", seeAll: "Tüm üyeleri gör" },
  vi: { title: "Thành viên khác giống {{name}}", seeAll: "Xem tất cả thành viên" },
};

const FILE_TO_KEY = {
  "kor.json": "kor",
  "ja.json": "ja",
  "zho.json": "zho",
  "zh_TW.json": "zh_TW",
  "ar.json": "ar",
  "de.json": "de",
  "es.json": "es",
  "fr.json": "fr",
  "hi.json": "hi",
  "id.json": "id",
  "it.json": "it",
  "pt.json": "pt",
  "ru.json": "ru",
  "th.json": "th",
  "tl.json": "tl",
  "tr.json": "tr",
  "vi.json": "vi",
};

let updated = 0;
for (const [file, key] of Object.entries(FILE_TO_KEY)) {
  const fp = path.join(localesDir, file);
  const json = JSON.parse(fs.readFileSync(fp, "utf8"));
  if (!json.communityDetail) {
    console.warn(`SKIP ${file}: no communityDetail root`);
    continue;
  }
  json.communityDetail.suggested = TRANSLATIONS[key];
  fs.writeFileSync(fp, JSON.stringify(json, null, 2) + "\n", "utf8");
  updated += 1;
  console.log(`✓ ${file}`);
}
console.log(`Updated ${updated} locale files.`);
