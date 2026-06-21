#!/usr/bin/env node
/* eslint-disable */
// Inject moments_section.{lightbox,share,create} sub-objects into every
// locale file. Idempotent — re-running overwrites with the same values.
const fs = require("fs");
const path = require("path");

const localesDir = path.resolve(__dirname, "..", "src", "utils", "locales");

const TRANSLATIONS = {
  kor: {
    lightbox: {
      open: "이미지를 전체 크기로 열기",
      close: "이미지 뷰어 닫기",
      previous: "이전 이미지",
      next: "다음 이미지",
    },
    share: {
      fallbackTitle: "이 모먼트를 확인해 보세요",
      success: "공유되었습니다!",
      copied: "링크가 클립보드에 복사되었습니다!",
      failed: "링크 복사에 실패했습니다",
    },
    create: {
      header: "모먼트 만들기",
      titlePlaceholder: "제목 추가...",
      addToMoment: "모먼트에 추가",
      addPhotos: "사진 추가",
      addMood: "기분 추가",
      addLocation: "위치 추가",
      addTags: "태그 추가",
      tagPlaceholder: "태그 추가...",
    },
  },
  ja: {
    lightbox: {
      open: "画像をフルサイズで開く",
      close: "画像ビューアを閉じる",
      previous: "前の画像",
      next: "次の画像",
    },
    share: {
      fallbackTitle: "このモーメントをチェック",
      success: "共有しました!",
      copied: "リンクをコピーしました!",
      failed: "リンクのコピーに失敗しました",
    },
    create: {
      header: "モーメントを作成",
      titlePlaceholder: "タイトルを追加...",
      addToMoment: "モーメントに追加",
      addPhotos: "写真を追加",
      addMood: "気分を追加",
      addLocation: "場所を追加",
      addTags: "タグを追加",
      tagPlaceholder: "タグを追加...",
    },
  },
  zho: {
    lightbox: {
      open: "全屏查看图片",
      close: "关闭图片查看器",
      previous: "上一张",
      next: "下一张",
    },
    share: {
      fallbackTitle: "看看这条动态",
      success: "分享成功!",
      copied: "链接已复制到剪贴板!",
      failed: "复制链接失败",
    },
    create: {
      header: "创建动态",
      titlePlaceholder: "添加标题...",
      addToMoment: "添加到动态",
      addPhotos: "添加图片",
      addMood: "添加心情",
      addLocation: "添加位置",
      addTags: "添加标签",
      tagPlaceholder: "添加标签...",
    },
  },
  zh_TW: {
    lightbox: {
      open: "全螢幕檢視圖片",
      close: "關閉圖片檢視器",
      previous: "上一張",
      next: "下一張",
    },
    share: {
      fallbackTitle: "看看這則動態",
      success: "分享成功!",
      copied: "連結已複製到剪貼簿!",
      failed: "複製連結失敗",
    },
    create: {
      header: "建立動態",
      titlePlaceholder: "新增標題...",
      addToMoment: "新增至動態",
      addPhotos: "新增圖片",
      addMood: "新增心情",
      addLocation: "新增位置",
      addTags: "新增標籤",
      tagPlaceholder: "新增標籤...",
    },
  },
  ar: {
    lightbox: {
      open: "فتح الصورة بالحجم الكامل",
      close: "إغلاق عارض الصور",
      previous: "الصورة السابقة",
      next: "الصورة التالية",
    },
    share: {
      fallbackTitle: "تحقق من هذه اللحظة",
      success: "تمت المشاركة بنجاح!",
      copied: "تم نسخ الرابط إلى الحافظة!",
      failed: "فشل نسخ الرابط",
    },
    create: {
      header: "إنشاء لحظة",
      titlePlaceholder: "أضف عنوانًا...",
      addToMoment: "أضف إلى لحظتك",
      addPhotos: "أضف الصور",
      addMood: "أضف المزاج",
      addLocation: "أضف الموقع",
      addTags: "أضف الوسوم",
      tagPlaceholder: "أضف وسمًا...",
    },
  },
  de: {
    lightbox: {
      open: "Bild in voller Größe öffnen",
      close: "Bildansicht schließen",
      previous: "Vorheriges Bild",
      next: "Nächstes Bild",
    },
    share: {
      fallbackTitle: "Schau dir diesen Moment an",
      success: "Erfolgreich geteilt!",
      copied: "Link in die Zwischenablage kopiert!",
      failed: "Link konnte nicht kopiert werden",
    },
    create: {
      header: "Moment erstellen",
      titlePlaceholder: "Titel hinzufügen...",
      addToMoment: "Zu deinem Moment hinzufügen",
      addPhotos: "Fotos hinzufügen",
      addMood: "Stimmung hinzufügen",
      addLocation: "Ort hinzufügen",
      addTags: "Tags hinzufügen",
      tagPlaceholder: "Tag hinzufügen...",
    },
  },
  es: {
    lightbox: {
      open: "Abrir imagen a tamaño completo",
      close: "Cerrar visor de imágenes",
      previous: "Imagen anterior",
      next: "Imagen siguiente",
    },
    share: {
      fallbackTitle: "Mira este momento",
      success: "¡Compartido con éxito!",
      copied: "¡Enlace copiado al portapapeles!",
      failed: "No se pudo copiar el enlace",
    },
    create: {
      header: "Crear momento",
      titlePlaceholder: "Añadir un título...",
      addToMoment: "Añadir a tu momento",
      addPhotos: "Añadir fotos",
      addMood: "Añadir estado de ánimo",
      addLocation: "Añadir ubicación",
      addTags: "Añadir etiquetas",
      tagPlaceholder: "Añadir una etiqueta...",
    },
  },
  fr: {
    lightbox: {
      open: "Ouvrir l'image en taille réelle",
      close: "Fermer la visionneuse d'images",
      previous: "Image précédente",
      next: "Image suivante",
    },
    share: {
      fallbackTitle: "Découvrez ce moment",
      success: "Partagé avec succès !",
      copied: "Lien copié dans le presse-papiers !",
      failed: "Impossible de copier le lien",
    },
    create: {
      header: "Créer un moment",
      titlePlaceholder: "Ajouter un titre...",
      addToMoment: "Ajouter à votre moment",
      addPhotos: "Ajouter des photos",
      addMood: "Ajouter une humeur",
      addLocation: "Ajouter un lieu",
      addTags: "Ajouter des tags",
      tagPlaceholder: "Ajouter un tag...",
    },
  },
  hi: {
    lightbox: {
      open: "छवि को पूर्ण आकार में खोलें",
      close: "छवि व्यूअर बंद करें",
      previous: "पिछली छवि",
      next: "अगली छवि",
    },
    share: {
      fallbackTitle: "इस पल को देखें",
      success: "सफलतापूर्वक साझा किया गया!",
      copied: "लिंक क्लिपबोर्ड पर कॉपी हो गया!",
      failed: "लिंक कॉपी करने में विफल",
    },
    create: {
      header: "पल बनाएँ",
      titlePlaceholder: "शीर्षक जोड़ें...",
      addToMoment: "अपने पल में जोड़ें",
      addPhotos: "फ़ोटो जोड़ें",
      addMood: "मूड जोड़ें",
      addLocation: "स्थान जोड़ें",
      addTags: "टैग जोड़ें",
      tagPlaceholder: "टैग जोड़ें...",
    },
  },
  id: {
    lightbox: {
      open: "Buka gambar ukuran penuh",
      close: "Tutup penampil gambar",
      previous: "Gambar sebelumnya",
      next: "Gambar berikutnya",
    },
    share: {
      fallbackTitle: "Lihat momen ini",
      success: "Berhasil dibagikan!",
      copied: "Tautan disalin ke clipboard!",
      failed: "Gagal menyalin tautan",
    },
    create: {
      header: "Buat momen",
      titlePlaceholder: "Tambahkan judul...",
      addToMoment: "Tambahkan ke momen Anda",
      addPhotos: "Tambahkan foto",
      addMood: "Tambahkan suasana hati",
      addLocation: "Tambahkan lokasi",
      addTags: "Tambahkan tag",
      tagPlaceholder: "Tambahkan tag...",
    },
  },
  it: {
    lightbox: {
      open: "Apri immagine a dimensione intera",
      close: "Chiudi visualizzatore immagini",
      previous: "Immagine precedente",
      next: "Immagine successiva",
    },
    share: {
      fallbackTitle: "Guarda questo momento",
      success: "Condiviso con successo!",
      copied: "Link copiato negli appunti!",
      failed: "Impossibile copiare il link",
    },
    create: {
      header: "Crea momento",
      titlePlaceholder: "Aggiungi un titolo...",
      addToMoment: "Aggiungi al tuo momento",
      addPhotos: "Aggiungi foto",
      addMood: "Aggiungi umore",
      addLocation: "Aggiungi posizione",
      addTags: "Aggiungi tag",
      tagPlaceholder: "Aggiungi un tag...",
    },
  },
  pt: {
    lightbox: {
      open: "Abrir imagem em tamanho completo",
      close: "Fechar visualizador de imagens",
      previous: "Imagem anterior",
      next: "Próxima imagem",
    },
    share: {
      fallbackTitle: "Veja este momento",
      success: "Compartilhado com sucesso!",
      copied: "Link copiado para a área de transferência!",
      failed: "Falha ao copiar o link",
    },
    create: {
      header: "Criar momento",
      titlePlaceholder: "Adicionar um título...",
      addToMoment: "Adicionar ao seu momento",
      addPhotos: "Adicionar fotos",
      addMood: "Adicionar humor",
      addLocation: "Adicionar localização",
      addTags: "Adicionar tags",
      tagPlaceholder: "Adicionar uma tag...",
    },
  },
  ru: {
    lightbox: {
      open: "Открыть изображение в полном размере",
      close: "Закрыть просмотр изображений",
      previous: "Предыдущее изображение",
      next: "Следующее изображение",
    },
    share: {
      fallbackTitle: "Посмотрите этот момент",
      success: "Успешно опубликовано!",
      copied: "Ссылка скопирована в буфер обмена!",
      failed: "Не удалось скопировать ссылку",
    },
    create: {
      header: "Создать момент",
      titlePlaceholder: "Добавить заголовок...",
      addToMoment: "Добавить к моменту",
      addPhotos: "Добавить фото",
      addMood: "Добавить настроение",
      addLocation: "Добавить место",
      addTags: "Добавить теги",
      tagPlaceholder: "Добавить тег...",
    },
  },
  th: {
    lightbox: {
      open: "เปิดภาพแบบเต็มขนาด",
      close: "ปิดโปรแกรมดูภาพ",
      previous: "ภาพก่อนหน้า",
      next: "ภาพถัดไป",
    },
    share: {
      fallbackTitle: "ดูช่วงเวลานี้สิ",
      success: "แชร์สำเร็จ!",
      copied: "คัดลอกลิงก์ไปยังคลิปบอร์ดแล้ว!",
      failed: "คัดลอกลิงก์ไม่สำเร็จ",
    },
    create: {
      header: "สร้างช่วงเวลา",
      titlePlaceholder: "เพิ่มหัวข้อ...",
      addToMoment: "เพิ่มในช่วงเวลาของคุณ",
      addPhotos: "เพิ่มรูปภาพ",
      addMood: "เพิ่มอารมณ์",
      addLocation: "เพิ่มสถานที่",
      addTags: "เพิ่มแท็ก",
      tagPlaceholder: "เพิ่มแท็ก...",
    },
  },
  tl: {
    lightbox: {
      open: "Buksan ang larawan sa buong sukat",
      close: "Isara ang viewer ng larawan",
      previous: "Nakaraang larawan",
      next: "Susunod na larawan",
    },
    share: {
      fallbackTitle: "Tingnan ang sandaling ito",
      success: "Naibahagi nang matagumpay!",
      copied: "Nakopya ang link sa clipboard!",
      failed: "Hindi makopya ang link",
    },
    create: {
      header: "Gumawa ng moment",
      titlePlaceholder: "Magdagdag ng pamagat...",
      addToMoment: "Idagdag sa iyong moment",
      addPhotos: "Magdagdag ng mga larawan",
      addMood: "Magdagdag ng mood",
      addLocation: "Magdagdag ng lokasyon",
      addTags: "Magdagdag ng mga tag",
      tagPlaceholder: "Magdagdag ng tag...",
    },
  },
  tr: {
    lightbox: {
      open: "Görseli tam boyutunda aç",
      close: "Görsel görüntüleyiciyi kapat",
      previous: "Önceki görsel",
      next: "Sonraki görsel",
    },
    share: {
      fallbackTitle: "Bu anı keşfedin",
      success: "Başarıyla paylaşıldı!",
      copied: "Bağlantı panoya kopyalandı!",
      failed: "Bağlantı kopyalanamadı",
    },
    create: {
      header: "Moment oluştur",
      titlePlaceholder: "Başlık ekle...",
      addToMoment: "Moment'inize ekleyin",
      addPhotos: "Fotoğraf ekle",
      addMood: "Ruh hali ekle",
      addLocation: "Konum ekle",
      addTags: "Etiket ekle",
      tagPlaceholder: "Etiket ekle...",
    },
  },
  vi: {
    lightbox: {
      open: "Mở ảnh kích thước đầy đủ",
      close: "Đóng trình xem ảnh",
      previous: "Ảnh trước",
      next: "Ảnh tiếp theo",
    },
    share: {
      fallbackTitle: "Xem khoảnh khắc này",
      success: "Đã chia sẻ thành công!",
      copied: "Đã sao chép liên kết vào bộ nhớ tạm!",
      failed: "Không thể sao chép liên kết",
    },
    create: {
      header: "Tạo khoảnh khắc",
      titlePlaceholder: "Thêm tiêu đề...",
      addToMoment: "Thêm vào khoảnh khắc",
      addPhotos: "Thêm ảnh",
      addMood: "Thêm tâm trạng",
      addLocation: "Thêm vị trí",
      addTags: "Thêm thẻ",
      tagPlaceholder: "Thêm thẻ...",
    },
  },
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
  if (!json.moments_section) {
    console.warn(`SKIP ${file}: no moments_section root`);
    continue;
  }
  const additions = TRANSLATIONS[key];
  for (const subKey of Object.keys(additions)) {
    json.moments_section[subKey] = additions[subKey];
  }
  fs.writeFileSync(fp, JSON.stringify(json, null, 2) + "\n", "utf8");
  updated += 1;
  console.log(`✓ ${file}`);
}
console.log(`Updated ${updated} locale files.`);
