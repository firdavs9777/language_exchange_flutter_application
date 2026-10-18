import "@testing-library/jest-dom";
import React from "react";
import { render, screen, act } from "@testing-library/react";
import { openSurface, closeSurface, useSurfaceOpen, _resetSurfacesForTests } from "./surfaceRegistry";

const Probe: React.FC = () => <span>{useSurfaceOpen("download-popup") ? "open" : "closed"}</span>;

beforeEach(() => _resetSurfacesForTests());

it("tells subscribers when a surface opens and closes", () => {
  render(<Probe />);
  expect(screen.getByText("closed")).toBeInTheDocument();
  act(() => openSurface("download-popup"));
  expect(screen.getByText("open")).toBeInTheDocument();
  act(() => closeSurface("download-popup"));
  expect(screen.getByText("closed")).toBeInTheDocument();
});
