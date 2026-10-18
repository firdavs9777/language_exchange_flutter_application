import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import EditMyMoment from "./EditMyMoment";

const mockGetMomentDetails = jest.fn();
const mockUpdateMoment = jest.fn();
const mockUploadPhotos = jest.fn();
const mockNavigate = jest.fn();
const mockToastSuccess = jest.fn();
const mockToastError = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

jest.mock("react-router-dom", () => ({
  ...jest.requireActual("react-router-dom"),
  useNavigate: () => mockNavigate,
}));

jest.mock("react-toastify", () => ({
  Bounce: "bounce",
  toast: {
    success: (...args: any[]) => mockToastSuccess(...args),
    error: (...args: any[]) => mockToastError(...args),
  },
}));

jest.mock("../../store/slices/momentsSlice", () => ({
  useGetMomentDetailsQuery: (arg: any) => mockGetMomentDetails(arg),
  useUpdateMomentMutation: () => [mockUpdateMoment, { isLoading: false }],
  useUploadMomentPhotosMutation: () => [mockUploadPhotos, { isLoading: false }],
  useUploadMomentVideoMutation: () => [jest.fn(), { isLoading: false }],
  useUploadMomentAudioMutation: () => [jest.fn(), { isLoading: false }],
  useDeleteMomentVideoMutation: () => [jest.fn(), { isLoading: false }],
  useDeleteMomentAudioMutation: () => [jest.fn(), { isLoading: false }],
}));

let mockSchedulingEnabled = false;
jest.mock("../moments/lib/useMomentSchedulingEnabled", () => ({
  useMomentSchedulingEnabled: () => mockSchedulingEnabled,
}));

const resolved = () => ({ unwrap: () => Promise.resolve({ success: true }) });
const rejected = () => ({ unwrap: () => Promise.reject({ status: 500 }) });

const MOMENT = {
  _id: "m1",
  title: "Busan",
  description: "Sunset by the sea",
  user: { _id: "me" },
  imageUrls: ["https://cdn.test/a.jpg", "https://cdn.test/b.jpg"],
};

function renderEditor(data: any = { data: MOMENT }, isLoading = false) {
  mockGetMomentDetails.mockReturnValue({ data, isLoading });
  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user: { _id: "me" } } }) => state },
  });
  return render(
    <Provider store={store}>
      <MemoryRouter initialEntries={["/edit-moment/m1"]}>
        <Routes>
          <Route path="/edit-moment/:id" element={<EditMyMoment />} />
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

beforeEach(() => {
  jest.clearAllMocks();
  mockSchedulingEnabled = false;
  mockUpdateMoment.mockReturnValue(resolved());
  mockUploadPhotos.mockReturnValue(resolved());
});

it("fills the form from the moment and lists its current images", () => {
  renderEditor();
  expect((screen.getByTestId("edit-moment-title") as HTMLInputElement).value).toBe("Busan");
  expect(
    (screen.getByTestId("edit-moment-description") as HTMLTextAreaElement).value
  ).toBe("Sunset by the sea");
  expect(screen.getAllByTestId("existing-image")).toHaveLength(2);
});

it("shows a spinner while the moment loads", () => {
  renderEditor(undefined, true);
  expect(screen.getByTestId("edit-moment-loading")).toBeInTheDocument();
});

it("offers no remove on a stored photo: the server cannot remove one", () => {
  renderEditor();
  expect(screen.getAllByTestId("existing-image")).toHaveLength(2);
  expect(screen.queryByTestId("remove-existing-0")).not.toBeInTheDocument();
});

it("saves the edited title and description, then leaves for the list", async () => {
  renderEditor();
  fireEvent.change(screen.getByTestId("edit-moment-title"), {
    target: { value: "Busan at night" },
  });
  fireEvent.submit(screen.getByTestId("edit-moment-form"));

  await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
  // Only what changed is sent.
  expect(mockUpdateMoment.mock.calls[0][0]).toEqual({
    id: "m1",
    momentData: { title: "Busan at night" },
  });
  // No new files were chosen, so the photo endpoint is left alone.
  expect(mockUploadPhotos).not.toHaveBeenCalled();
  await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/my-moments"));
});

it("reports a failed save and stays on the form", async () => {
  mockUpdateMoment.mockReturnValue(rejected());
  renderEditor();
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "Changed" } });
  fireEvent.submit(screen.getByTestId("edit-moment-form"));

  await waitFor(() => expect(mockToastError).toHaveBeenCalled());
  expect(mockNavigate).not.toHaveBeenCalledWith("/my-moments");
});

it("saves a moment that has no title", async () => {
  renderEditor({ data: { ...MOMENT, title: "" } });
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "Only words" } });
  expect(screen.getByTestId("edit-moment-save")).not.toBeDisabled();
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
  expect(mockUpdateMoment.mock.calls[0][0].momentData).toEqual({ description: "Only words" });
});

it("refuses to save an empty description on a moment with no media", async () => {
  renderEditor({ data: { ...MOMENT, imageUrls: [], mediaType: "text" } });
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "  " } });
  expect(screen.getByTestId("edit-moment-save")).toBeDisabled();
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(mockUpdateMoment).not.toHaveBeenCalled());
});

it("saving with nothing changed sends nothing", async () => {
  renderEditor();
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  expect(await screen.findByText("Nothing to change yet")).toBeInTheDocument();
  expect(mockUpdateMoment).not.toHaveBeenCalled();
});

it("edits mood, category, language, privacy and tags", async () => {
  renderEditor({ data: { ...MOMENT, tags: ["sea"], language: "ko" } });
  fireEvent.click(screen.getByRole("button", { name: /Grateful/ }));
  fireEvent.change(screen.getByLabelText("Category"), { target: { value: "food" } });
  fireEvent.change(screen.getByLabelText("Language"), { target: { value: "ja" } });
  fireEvent.click(screen.getByRole("button", { name: /Only me/ }));
  fireEvent.click(screen.getByRole("button", { name: "Remove sea" }));
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
  expect(mockUpdateMoment.mock.calls[0][0].momentData).toEqual({
    mood: "grateful",
    category: "food",
    language: "ja",
    privacy: "private",
    tags: [],
  });
});

it("a text moment can change its background; a photo moment is not offered one", () => {
  renderEditor();
  expect(screen.queryByLabelText("gradient_ocean")).not.toBeInTheDocument();
});

it("changes a text moment's background", async () => {
  renderEditor({ data: { ...MOMENT, imageUrls: [], mediaType: "text", backgroundColor: "" } });
  fireEvent.click(screen.getByLabelText("gradient_ocean"));
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
  expect(mockUpdateMoment.mock.calls[0][0].momentData).toEqual({ backgroundColor: "gradient_ocean" });
});

it("removes a location", async () => {
  renderEditor({
    data: { ...MOMENT, location: { formattedAddress: "Busan, Korea", type: "Point", coordinates: [129, 35] } },
  });
  fireEvent.click(screen.getByRole("button", { name: "Remove location" }));
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
  expect(mockUpdateMoment.mock.calls[0][0].momentData).toEqual({ location: null });
});

describe("schedule", () => {
  const later = { ...MOMENT, scheduledFor: "2099-05-01T09:00:00.000Z" };

  it("is offered while the moment is unpublished and scheduling is enforced", () => {
    mockSchedulingEnabled = true;
    renderEditor({ data: later });
    expect(screen.getByLabelText("Schedule")).toBeInTheDocument();
  });

  it("is not offered for a published moment", () => {
    mockSchedulingEnabled = true;
    renderEditor();
    expect(screen.queryByLabelText("Schedule")).not.toBeInTheDocument();
  });

  it("is not offered while scheduling is not enforced", () => {
    renderEditor({ data: later });
    expect(screen.queryByLabelText("Schedule")).not.toBeInTheDocument();
  });

  it("Post now instead sends a cleared schedule", async () => {
    mockSchedulingEnabled = true;
    renderEditor({ data: later });
    fireEvent.click(screen.getByRole("button", { name: "Post now instead" }));
    fireEvent.submit(screen.getByTestId("edit-moment-form"));
    await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
    expect(mockUpdateMoment.mock.calls[0][0].momentData).toEqual({ scheduledFor: null });
  });
});

it("bounces someone who does not own the moment", () => {
  renderEditor({ data: { ...MOMENT, user: { _id: "someone-else" } } });
  expect(mockToastError).toHaveBeenCalled();
  expect(mockNavigate).toHaveBeenCalledWith("/moments");
});

it("uses no react-bootstrap markup and no emoji", () => {
  const { container } = renderEditor();
  expect(
    container.querySelectorAll(".btn, .card, .row, .col, .form-control, .container")
  ).toHaveLength(0);
  expect(container.textContent).not.toMatch(
    /[\u{1F300}-\u{1FAFF}\u{2190}-\u{21FF}\u{2700}-\u{27BF}]/u
  );
});

describe("media", () => {
  it("a video moment shows its video editor and no photo section", () => {
    renderEditor({ data: { ...MOMENT, imageUrls: [], mediaType: "video", video: { url: "https://cdn/v.mp4" } } });
    expect(screen.getByTestId("media-editor")).toBeInTheDocument();
    expect(screen.queryByTestId("edit-moment-add-images")).not.toBeInTheDocument();
  });

  it("a photo moment has no media editor", () => {
    renderEditor();
    expect(screen.queryByTestId("media-editor")).not.toBeInTheDocument();
    expect(screen.getByTestId("edit-moment-add-images")).toBeInTheDocument();
  });
});

describe("review fixes", () => {
  it("a refetch after a media change keeps what the reader has typed", () => {
    const video = { ...MOMENT, imageUrls: [], mediaType: "video", video: { url: "https://cdn/v1.mp4" } };
    mockGetMomentDetails.mockReturnValue({ data: { data: video }, isLoading: false });
    const store = configureStore({
      reducer: { auth: (state: any = { userInfo: { user: { _id: "me" } } }) => state },
    });
    const tree = (
      <Provider store={store}>
        <MemoryRouter initialEntries={["/edit-moment/m1"]}>
          <Routes>
            <Route path="/edit-moment/:id" element={<EditMyMoment />} />
          </Routes>
        </MemoryRouter>
      </Provider>
    );
    const { rerender } = render(tree);
    fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "Rewritten" } });
    // The video was replaced: the detail query refetches a new object.
    mockGetMomentDetails.mockReturnValue({
      data: { data: { ...video, video: { url: "https://cdn/v2.mp4" } } },
      isLoading: false,
    });
    rerender(tree);
    // Any state change re-renders the editor with the refetched moment.
    fireEvent.change(screen.getByTestId("edit-moment-title"), { target: { value: "New title" } });
    expect((screen.getByTestId("edit-moment-description") as HTMLTextAreaElement).value).toBe("Rewritten");
    expect((screen.getByTestId("edit-moment-title") as HTMLInputElement).value).toBe("New title");
  });

  it("an untouched schedule with seconds is never re-sent", async () => {
    mockSchedulingEnabled = true;
    renderEditor({ data: { ...MOMENT, scheduledFor: "2099-05-01T09:00:42.000Z" } });
    fireEvent.click(screen.getByRole("button", { name: /Grateful/ }));
    fireEvent.submit(screen.getByTestId("edit-moment-form"));
    await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
    expect(mockUpdateMoment.mock.calls[0][0].momentData).toEqual({ mood: "grateful" });
  });
});

it("clears the caption of a photo moment (moments#4)", async () => {
  renderEditor();
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "" } });
  expect(screen.getByTestId("edit-moment-save")).not.toBeDisabled();
  expect(screen.getByTestId("edit-moment-description")).not.toBeRequired();
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(mockUpdateMoment).toHaveBeenCalledTimes(1));
  expect(mockUpdateMoment.mock.calls[0][0].momentData).toEqual({ description: "" });
});

it("clears the caption of a video moment", async () => {
  renderEditor({
    data: { ...MOMENT, imageUrls: [], mediaType: "video", video: { url: "https://cdn.test/v.mp4" } },
  });
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "" } });
  expect(screen.getByTestId("edit-moment-save")).not.toBeDisabled();
});

it("a text moment that gains photos and loses its caption uploads the photos first", async () => {
  const order: string[] = [];
  mockUploadPhotos.mockImplementation(() => {
    order.push("upload");
    return resolved();
  });
  mockUpdateMoment.mockImplementation(() => {
    order.push("update");
    return resolved();
  });
  const originalCreate = (URL as any).createObjectURL;
  (URL as any).createObjectURL = jest.fn(() => "blob:preview");
  // jsdom has no revokeObjectURL either; the editor revokes its previews on unmount.
  if (!(URL as any).revokeObjectURL) (URL as any).revokeObjectURL = jest.fn();
  const { container } = renderEditor({ data: { ...MOMENT, imageUrls: [], mediaType: "text" } });
  const input = container.querySelector('input[type="file"]') as HTMLInputElement;
  fireEvent.change(input, { target: { files: [new File(["x"], "a.jpg", { type: "image/jpeg" })] } });
  fireEvent.change(screen.getByTestId("edit-moment-description"), { target: { value: "" } });
  fireEvent.submit(screen.getByTestId("edit-moment-form"));
  await waitFor(() => expect(order).toEqual(["upload", "update"]));
  (URL as any).createObjectURL = originalCreate;
});

it("shows no title field for a moment that has no title (moments#6)", () => {
  renderEditor({ data: { ...MOMENT, title: "" } });
  expect(screen.queryByTestId("edit-moment-title")).not.toBeInTheDocument();
});

it("keeps the title field for a legacy moment that has one", () => {
  renderEditor();
  expect(screen.getByTestId("edit-moment-title")).toBeInTheDocument();
});
