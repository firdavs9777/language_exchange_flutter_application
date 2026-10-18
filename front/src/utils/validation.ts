// Shared validation constants that mirror the backend's own rules, so the
// client rejects exactly what the schema would.

/**
 * The email shape the model enforces
 * (`language_exchange_backend_application/models/User.js`'s `email.match`).
 * Copied verbatim -- keep the two in sync by hand if the model ever changes.
 */
export const EMAIL_RE =
  /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
