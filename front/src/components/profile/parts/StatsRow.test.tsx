import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import StatsRow from "./StatsRow";

const base = {
  followers: 12,
  following: 7,
  moments: 3,
  visitors: 42,
};

it("gates the visitors tile with VIP + lock when not vip", () => {
  render(<StatsRow {...base} isVip={false} />);
  const visitors = screen.getByTestId("stat-visitors");
  expect(visitors).toHaveTextContent("VIP");
  expect(visitors).not.toHaveTextContent("42");
});

it("shows the visitor count when vip", () => {
  render(<StatsRow {...base} isVip />);
  const visitors = screen.getByTestId("stat-visitors");
  expect(visitors).toHaveTextContent("42");
  expect(visitors).not.toHaveTextContent("VIP");
});

it("fires stat callbacks when tiles are clicked", () => {
  const onFollowers = jest.fn();
  const onVisitors = jest.fn();
  render(
    <StatsRow {...base} isVip onFollowers={onFollowers} onVisitors={onVisitors} />
  );
  fireEvent.click(screen.getByTestId("stat-followers"));
  fireEvent.click(screen.getByTestId("stat-visitors"));
  expect(onFollowers).toHaveBeenCalledTimes(1);
  expect(onVisitors).toHaveBeenCalledTimes(1);
});
