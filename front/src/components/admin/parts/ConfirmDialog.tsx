// Moved to src/design/ConfirmDialog.tsx — the profile asks "are you sure?" for
// block and report the same way the admin console asks it for a ban, so the
// dialog is a design primitive now rather than an admin part.
//
// This re-export keeps the admin console's existing imports working. A default
// export is a runtime value, so re-exporting it here is safe under the repo's
// typescript@3.7.2 (unlike an interface, which has no runtime binding — import
// `ConfirmDialogProps` straight from src/design/ConfirmDialog).
export { default } from "../../../design/ConfirmDialog";
