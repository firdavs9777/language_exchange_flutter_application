#!/usr/bin/env node
/* eslint-disable */
// Inject chatPage.actions.* into every locale file.
const fs = require("fs");
const path = require("path");

const localesDir = path.resolve(__dirname, "..", "src", "utils", "locales");

const T = {
  kor: { menuLabel: "대화 옵션", pin: "고정", unpin: "고정 해제", pinned: "고정됨", noConversationYet: "먼저 대화를 시작해야 고정할 수 있습니다", pinFailed: "고정 변경에 실패했습니다", deleteFailed: "대화 삭제에 실패했습니다", deleted: "대화가 삭제되었습니다" },
  ja: { menuLabel: "会話のオプション", pin: "ピン留め", unpin: "ピン留め解除", pinned: "ピン留め済み", noConversationYet: "ピン留めするには先に会話を開始してください", pinFailed: "ピン留めの変更に失敗しました", deleteFailed: "会話の削除に失敗しました", deleted: "会話を削除しました" },
  zho: { menuLabel: "对话操作", pin: "置顶", unpin: "取消置顶", pinned: "已置顶", noConversationYet: "请先开始对话再置顶", pinFailed: "更新置顶失败", deleteFailed: "删除对话失败", deleted: "对话已删除" },
  zh_TW: { menuLabel: "對話操作", pin: "置頂", unpin: "取消置頂", pinned: "已置頂", noConversationYet: "請先開始對話再置頂", pinFailed: "更新置頂失敗", deleteFailed: "刪除對話失敗", deleted: "對話已刪除" },
  ar: { menuLabel: "إجراءات المحادثة", pin: "تثبيت", unpin: "إلغاء التثبيت", pinned: "مثبت", noConversationYet: "ابدأ المحادثة أولًا لتثبيتها", pinFailed: "تعذر تحديث التثبيت", deleteFailed: "تعذر حذف المحادثة", deleted: "تم حذف المحادثة" },
  de: { menuLabel: "Konversationsaktionen", pin: "Anheften", unpin: "Lösen", pinned: "Angeheftet", noConversationYet: "Starte zuerst die Konversation, um sie anzuheften", pinFailed: "Anheften konnte nicht aktualisiert werden", deleteFailed: "Konversation konnte nicht gelöscht werden", deleted: "Konversation gelöscht" },
  es: { menuLabel: "Acciones de la conversación", pin: "Fijar", unpin: "Desfijar", pinned: "Fijada", noConversationYet: "Inicia la conversación primero para fijarla", pinFailed: "No se pudo actualizar el fijado", deleteFailed: "No se pudo eliminar la conversación", deleted: "Conversación eliminada" },
  fr: { menuLabel: "Actions de la conversation", pin: "Épingler", unpin: "Désépingler", pinned: "Épinglée", noConversationYet: "Démarrez d'abord la conversation pour l'épingler", pinFailed: "Impossible de modifier l'épinglage", deleteFailed: "Impossible de supprimer la conversation", deleted: "Conversation supprimée" },
  hi: { menuLabel: "बातचीत क्रियाएँ", pin: "पिन करें", unpin: "अनपिन करें", pinned: "पिन किया गया", noConversationYet: "पिन करने के लिए पहले बातचीत शुरू करें", pinFailed: "पिन अपडेट करने में विफल", deleteFailed: "बातचीत हटाने में विफल", deleted: "बातचीत हटा दी गई" },
  id: { menuLabel: "Aksi percakapan", pin: "Sematkan", unpin: "Lepas sematan", pinned: "Disematkan", noConversationYet: "Mulai percakapan terlebih dahulu untuk menyematkannya", pinFailed: "Gagal memperbarui sematan", deleteFailed: "Gagal menghapus percakapan", deleted: "Percakapan dihapus" },
  it: { menuLabel: "Azioni della conversazione", pin: "Fissa", unpin: "Rimuovi", pinned: "Fissata", noConversationYet: "Avvia prima la conversazione per fissarla", pinFailed: "Impossibile aggiornare il fissaggio", deleteFailed: "Impossibile eliminare la conversazione", deleted: "Conversazione eliminata" },
  pt: { menuLabel: "Ações da conversa", pin: "Fixar", unpin: "Desafixar", pinned: "Fixada", noConversationYet: "Inicie a conversa primeiro para fixá-la", pinFailed: "Não foi possível atualizar a fixação", deleteFailed: "Não foi possível excluir a conversa", deleted: "Conversa excluída" },
  ru: { menuLabel: "Действия с диалогом", pin: "Закрепить", unpin: "Открепить", pinned: "Закреплён", noConversationYet: "Сначала начните диалог, чтобы закрепить", pinFailed: "Не удалось обновить закрепление", deleteFailed: "Не удалось удалить диалог", deleted: "Диалог удалён" },
  th: { menuLabel: "ตัวเลือกการสนทนา", pin: "ปักหมุด", unpin: "เลิกปักหมุด", pinned: "ปักหมุดแล้ว", noConversationYet: "เริ่มการสนทนาก่อนเพื่อปักหมุด", pinFailed: "อัปเดตการปักหมุดไม่สำเร็จ", deleteFailed: "ลบการสนทนาไม่สำเร็จ", deleted: "ลบการสนทนาแล้ว" },
  tl: { menuLabel: "Mga aksyon sa usapan", pin: "I-pin", unpin: "Tanggalin ang pin", pinned: "Naka-pin", noConversationYet: "Simulan muna ang usapan bago i-pin", pinFailed: "Hindi nai-update ang pin", deleteFailed: "Hindi nabura ang usapan", deleted: "Naburas ang usapan" },
  tr: { menuLabel: "Sohbet işlemleri", pin: "Sabitle", unpin: "Sabitlemeyi kaldır", pinned: "Sabitlendi", noConversationYet: "Sabitlemek için önce sohbeti başlatın", pinFailed: "Sabitleme güncellenemedi", deleteFailed: "Sohbet silinemedi", deleted: "Sohbet silindi" },
  vi: { menuLabel: "Tùy chọn cuộc trò chuyện", pin: "Ghim", unpin: "Bỏ ghim", pinned: "Đã ghim", noConversationYet: "Hãy bắt đầu cuộc trò chuyện trước khi ghim", pinFailed: "Không thể cập nhật ghim", deleteFailed: "Không thể xóa cuộc trò chuyện", deleted: "Đã xóa cuộc trò chuyện" },
};

const FILE_TO_KEY = { "kor.json": "kor", "ja.json": "ja", "zho.json": "zho", "zh_TW.json": "zh_TW", "ar.json": "ar", "de.json": "de", "es.json": "es", "fr.json": "fr", "hi.json": "hi", "id.json": "id", "it.json": "it", "pt.json": "pt", "ru.json": "ru", "th.json": "th", "tl.json": "tl", "tr.json": "tr", "vi.json": "vi" };

let updated = 0;
for (const [file, key] of Object.entries(FILE_TO_KEY)) {
  const fp = path.join(localesDir, file);
  const json = JSON.parse(fs.readFileSync(fp, "utf8"));
  if (!json.chatPage) { console.warn(`SKIP ${file}: no chatPage root`); continue; }
  json.chatPage.actions = T[key];
  fs.writeFileSync(fp, JSON.stringify(json, null, 2) + "\n", "utf8");
  updated += 1;
  console.log(`✓ ${file}`);
}
console.log(`Updated ${updated} locale files.`);
