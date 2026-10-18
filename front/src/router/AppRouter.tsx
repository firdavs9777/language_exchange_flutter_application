import { createBrowserRouter } from "react-router-dom";
import { routes } from "./routes";

// Browser-only: createBrowserRouter reads window.location when created. The
// prerender step imports ./routes directly and never this file.
const AppRouter = createBrowserRouter(routes);

export default AppRouter;
