import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import MatchCard from "./MatchCard";

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: (key: string, o?: any) => (o && o.defaultValue !== undefined ? o.defaultValue : key), i18n: { language: "en" } }),
}));

const match = {
  user: { _id: "u7", name: "Mina", images: ["https://cdn.x/m.jpg"], native_language: "Korean", language_to_learn: "English", location: { country: "South Korea" } },
  matchReasons: ["reciprocal_pair", "active_today"],
  lastActiveBucket: "today",
  responseRate: 0.8,
  boosted: true,
};

const renderCard = (over: any = {}, handlers: any = {}) =>
  render(
    <MemoryRouter>
      <MatchCard match={{ ...match, ...over } as any} onWave={handlers.onWave || jest.fn()} onSkip={handlers.onSkip || jest.fn()} />
    </MemoryRouter>
  );

describe("MatchCard", () => {
  it("shows who they are and why they matched", () => {
    renderCard();
    expect(screen.getByTestId("match-card-name")).toHaveTextContent("Mina");
    expect(screen.getByTestId("match-card-name")).toHaveTextContent("🇰🇷");
    expect(screen.getByTestId("match-pair")).toHaveTextContent("Korean → English");
    expect(screen.getAllByTestId("match-reason")).toHaveLength(2);
    expect(screen.getByTestId("match-active-dot")).toBeInTheDocument();
    expect(screen.getByTestId("match-replies-fast")).toBeInTheDocument();
    expect(screen.getByTestId("match-boosted")).toBeInTheDocument();
  });

  it("leaves out what does not apply", () => {
    renderCard({ lastActiveBucket: "this_week", responseRate: null, boosted: undefined, matchReasons: [] });
    expect(screen.queryByTestId("match-active-dot")).not.toBeInTheDocument();
    expect(screen.queryByTestId("match-replies-fast")).not.toBeInTheDocument();
    expect(screen.queryByTestId("match-boosted")).not.toBeInTheDocument();
    expect(screen.queryByTestId("match-reason")).not.toBeInTheDocument();
  });

  it("drops an empty side of the language pair", () => {
    renderCard({ user: { ...match.user, language_to_learn: "" } });
    expect(screen.getByTestId("match-pair")).toHaveTextContent(/^Korean$/);
  });

  it("Say hi opens the chat; name and photo open the profile", () => {
    renderCard();
    expect(screen.getByTestId("match-say-hi")).toHaveAttribute("href", "/chat/u7");
    expect(screen.getByTestId("match-profile-link")).toHaveAttribute("href", "/community/u7");
  });

  it("Wave and Skip hand the match to their handlers", () => {
    const onWave = jest.fn();
    const onSkip = jest.fn();
    renderCard({}, { onWave, onSkip });
    fireEvent.click(screen.getByTestId("match-wave"));
    fireEvent.click(screen.getByTestId("match-skip"));
    expect(onWave).toHaveBeenCalledWith(expect.objectContaining({ user: expect.objectContaining({ _id: "u7" }) }));
    expect(onSkip).toHaveBeenCalledWith(expect.objectContaining({ user: expect.objectContaining({ _id: "u7" }) }));
  });

  it("shows a disabled Waved state instead of Wave once waved", () => {
    const onWave = jest.fn();
    render(
      <MemoryRouter>
        <MatchCard match={match as any} onWave={onWave} onSkip={jest.fn()} waved />
      </MemoryRouter>
    );
    expect(screen.queryByTestId("match-wave")).not.toBeInTheDocument();
    const done = screen.getByTestId("match-waved");
    expect(done).toBeDisabled();
    fireEvent.click(done);
    expect(onWave).not.toHaveBeenCalled();
  });
});
