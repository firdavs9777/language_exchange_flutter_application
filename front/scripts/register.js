// Node-side module hooks so scripts/prerender.js can require the CRA app.
// Babel compiles TS/JSX with the presets below; styles are stubbed the way
// CRA's Jest config stubs them; media imports resolve to their hashed build
// URLs so prerendered <img src> matches what the client would render.
const path = require("path");
const fs = require("fs");

process.env.NODE_ENV = process.env.NODE_ENV || "production";
process.env.BABEL_ENV = process.env.NODE_ENV;
// CRA's cascade: .env is the shared base, .env.production wins over it.
const ROOT = path.join(__dirname, "..");
require("dotenv").config({ path: path.join(ROOT, ".env") });
require("dotenv").config({ path: path.join(ROOT, ".env.production"), override: true });

// The presets are spelled out rather than reused from babel-preset-react-app:
// that preset only emits CommonJS (what Node's require needs) in its "test"
// env, and its test env also hardcodes preset-react's `development: true`,
// which compiles JSX to jsxDEV -- a function React's *production* build does
// not ship. NODE_ENV stays "production" here so renderToString uses React's
// production build, so the JSX runtime has to be the production one too.
require("@babel/register")({
  extensions: [".js", ".jsx", ".ts", ".tsx"],
  presets: [
    [require.resolve("@babel/preset-env"), { targets: { node: "current" }, modules: "commonjs" }],
    [require.resolve("@babel/preset-react"), { runtime: "automatic", development: false }],
    [require.resolve("@babel/preset-typescript")],
  ],
  plugins: [require.resolve("babel-plugin-macros")],
  ignore: [/node_modules/],
  cache: true,
});

const STYLE_EXTS = [".css", ".scss", ".sass"];
const MEDIA_EXTS = [".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".ico", ".mp3", ".mp4", ".woff", ".woff2"];

const manifestPath = path.join(__dirname, "..", "build", "asset-manifest.json");
const manifest = fs.existsSync(manifestPath)
  ? JSON.parse(fs.readFileSync(manifestPath, "utf8")).files || {}
  : {};

for (const ext of STYLE_EXTS) {
  require.extensions[ext] = (m) => {
    m.exports = {};
  };
}
for (const ext of MEDIA_EXTS) {
  require.extensions[ext] = (m, filename) => {
    const base = path.basename(filename);
    const key = Object.keys(manifest).find((k) => k.startsWith("static/media/") && path.basename(k) === base);
    m.exports = key ? manifest[key] : `/static/media/${base}`;
  };
}
