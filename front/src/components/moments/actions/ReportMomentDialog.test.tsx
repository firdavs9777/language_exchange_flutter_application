import "@testing-library/jest-dom";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import ReportMomentDialog from "./ReportMomentDialog";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));
const mockReport = jest.fn();
jest.mock("../../../store/slices/usersSlice", () => ({
  useReportUserMutation: () => [mockReport, { isLoading: false }],
}));
jest.mock("../../../design/notify", () => ({
  __esModule: true,
  default: { success: jest.fn(), error: jest.fn(), info: jest.fn() },
}));

beforeEach(() => mockReport.mockReturnValue({ unwrap: () => Promise.resolve({}) }));

it.each([
  ["moment", "Report this moment"],
  ["comment", "Report this comment"],
  ["story", "Report this story"],
])("reports a %s with the canonical payload", async (type, title) => {
  render(<ReportMomentDialog type={type as any} targetId="t1" authorId="a1" onClose={() => undefined} />);
  expect(screen.getByText(title)).toBeInTheDocument();
  fireEvent.click(screen.getByLabelText("Spam"));
  fireEvent.click(screen.getByRole("button", { name: "Send report" }));
  await waitFor(() =>
    expect(mockReport).toHaveBeenCalledWith({
      type,
      reportId: "t1",
      reportedUser: "a1",
      reason: "spam",
      description: "",
    })
  );
});

it("says a comment was already reported in comment words", async () => {
  mockReport.mockReturnValue({
    unwrap: () => Promise.reject({ status: 400, data: { error: "You have already reported this" } }),
  });
  render(<ReportMomentDialog type="comment" targetId="c1" authorId="a1" onClose={() => undefined} />);
  fireEvent.click(screen.getByLabelText("Spam"));
  fireEvent.click(screen.getByRole("button", { name: "Send report" }));
  expect(await screen.findByText("You've already reported this comment.")).toBeInTheDocument();
});
