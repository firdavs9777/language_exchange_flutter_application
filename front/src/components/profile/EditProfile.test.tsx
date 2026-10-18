import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { Provider } from "react-redux";
import { configureStore } from "@reduxjs/toolkit";
import {
  createMemoryRouter,
  RouterProvider,
  createRoutesFromElements,
  Route,
} from "react-router-dom";
import EditProfile from "./EditProfile";

const mockGetUserProfile = jest.fn();
const mockUpdate = jest.fn();
const mockUpload = jest.fn();
const mockDeletePhoto = jest.fn();
const mockUpdateUserById = jest.fn();
const mockNavigate = jest.fn();
const mockToastSuccess = jest.fn();
const mockToastError = jest.fn();

jest.mock("react-i18next", () => ({
  useTranslation: () => ({ t: () => "", i18n: { language: "en" } }),
}));

// The date picker is a third-party widget with its own stylesheet; the editor
// only cares that the callback lands, so it stands in as a plain input.
jest.mock("react-datepicker", () => ({
  __esModule: true,
  default: (props: any) => (
    <input
      data-testid="edit-birthday"
      onChange={(event: any) => props.onChange(new Date(event.target.value))}
    />
  ),
}));
jest.mock("react-datepicker/dist/react-datepicker.css", () => ({}), { virtual: true });

jest.mock("react-toastify", () => ({
  Bounce: "bounce",
  toast: {
    success: (...args: any[]) => mockToastSuccess(...args),
    error: (...args: any[]) => mockToastError(...args),
  },
}));

jest.mock("../../store/slices/usersSlice", () => ({
  useGetUserProfileQuery: (arg: any) => mockGetUserProfile(arg),
  useUpdateUserInfoMutation: () => [mockUpdate, { isLoading: false }],
  useUploadUserPhotoMutation: () => [mockUpload, { isLoading: false }],
  useDeleteUserPhotoMutation: () => [mockDeletePhoto, { isLoading: false }],
  useUpdateUserByIdMutation: () => [mockUpdateUserById, { isLoading: false }],
}));

jest.mock("../../store/slices/authSlice", () => ({
  setCredentials: (payload: any) => ({ type: "auth/setCredentials", payload }),
}));

// `useNavigate` is stubbed for most cases so the redirect is a plain
// assertion, but the unsaved-changes guard has to be proved against the REAL
// router too: a save's own redirect must not be blocked by the form it just
// saved. `mockNavigation` is flipped before a render and never during one, so
// the hook count stays stable across that component's renders.
let mockNavigation = true;
jest.mock("react-router-dom", () => {
  const actual = jest.requireActual("react-router-dom");
  return {
    ...actual,
    useNavigate: () => (mockNavigation ? mockNavigate : actual.useNavigate()),
  };
});

const refetch = jest.fn();
const resolved = (value: any = { success: true }) => ({
  unwrap: () => Promise.resolve(value),
});
const rejected = (error: any = { data: { message: "nope" } }) => ({
  unwrap: () => Promise.reject(error),
});

const USER = {
  _id: "me",
  name: "Ada",
  birth_year: "1990",
  birth_month: "6",
  birth_day: "15",
  username: "ada",
  email: "ada@example.com",
  gender: "Female",
  bio: "Hello",
  native_language: "Korean",
  language_to_learn: "English",
  languageLevel: "B1",
  occupation: "Engineer",
  school: "KAIST",
  mbti: "INTJ",
  bloodType: "A",
  topics: ["music"],
  imageUrls: ["https://cdn.test/a.jpg", "https://cdn.test/b.jpg"],
};

function renderEditor(data: any = { data: USER }, loading = false) {
  mockGetUserProfile.mockReturnValue({ data, isLoading: loading, refetch });
  const store = configureStore({
    reducer: { auth: (state: any = { userInfo: { user: { _id: "me" } } }) => state },
  });
  // A data router, because the unsaved-changes guard is useBlocker — which
  // only exists inside one. src/index.tsx mounts the app the same way.
  const router = createMemoryRouter(
    createRoutesFromElements(
      <Route path="/">
        <Route path="profile/edit" element={<EditProfile />} />
        <Route path="profile" element={<div data-testid="profile-screen" />} />
      </Route>
    ),
    { initialEntries: ["/profile/edit"] }
  );
  return render(
    <Provider store={store}>
      <RouterProvider router={router} />
    </Provider>
  );
}

beforeEach(() => {
  jest.clearAllMocks();
  mockNavigation = true;
  mockUpdate.mockReturnValue(resolved());
  mockUpdateUserById.mockReturnValue(resolved());
  mockUpload.mockReturnValue(resolved());
  mockDeletePhoto.mockReturnValue(resolved());
});

describe("layout", () => {
  it("renders the four sections", () => {
    renderEditor();
    expect(screen.getByTestId("edit-photos")).toBeInTheDocument();
    expect(screen.getByTestId("edit-basics")).toBeInTheDocument();
    expect(screen.getByTestId("edit-languages")).toBeInTheDocument();
    expect(screen.getByTestId("edit-about")).toBeInTheDocument();
  });

  it("fills every field from the loaded document, About included", () => {
    renderEditor();
    expect((screen.getByTestId("edit-name") as HTMLInputElement).value).toBe("Ada");
    expect((screen.getByTestId("edit-occupation") as HTMLInputElement).value).toBe(
      "Engineer"
    );
    expect((screen.getByTestId("edit-school") as HTMLInputElement).value).toBe("KAIST");
    expect(screen.getByTestId("edit-level-B1")).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByTestId("edit-mbti-INTJ")).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByTestId("edit-blood-A")).toHaveAttribute("aria-pressed", "true");
    expect(screen.getByTestId("edit-topic-music")).toHaveAttribute("aria-pressed", "true");
    // Gender arrives capitalised from the API and still matches.
    expect(screen.getByTestId("edit-gender-female")).toHaveAttribute(
      "aria-pressed",
      "true"
    );
  });

  it("shows a spinner instead of an empty form while the profile loads", () => {
    renderEditor(undefined, true);
    expect(screen.getByTestId("edit-loading")).toBeInTheDocument();
    expect(screen.queryByTestId("edit-basics")).not.toBeInTheDocument();
  });

  it("uses no react-bootstrap markup and no emoji", () => {
    const { container } = renderEditor();
    expect(container.querySelectorAll(".btn, .card, .row, .col, .form-control")).toHaveLength(
      0
    );
    expect(container.textContent).not.toMatch(
      /[\u{1F300}-\u{1FAFF}\u{2190}-\u{21FF}\u{2700}-\u{27BF}]/u
    );
  });
});

describe("accessibility", () => {
  it("names every toggle group programmatically", () => {
    renderEditor();
    const groups = screen.getAllByRole("group");
    // Gender, level, intents, topics, MBTI, blood type.
    expect(groups).toHaveLength(6);
    groups.forEach((group) => {
      const id = group.getAttribute("aria-labelledby") || "";
      expect(id).toBeTruthy();
      expect(document.getElementById(id)).toBeTruthy();
    });
  });

  it("points the hints and counters at the controls they describe", () => {
    renderEditor();
    expect(screen.getByTestId("edit-bio")).toHaveAttribute(
      "aria-describedby",
      "edit-bio-count"
    );
    expect(screen.getByTestId("edit-username")).toHaveAttribute(
      "aria-describedby",
      "edit-username-hint"
    );
    expect(document.getElementById("edit-bio-count")).toBeTruthy();
    expect(document.getElementById("edit-username-hint")).toBeTruthy();
    expect(document.getElementById("edit-level-hint")).toBeTruthy();
  });
});

describe("completion", () => {
  // The app's ten fields (completion_calculator.dart), so a profile reads the
  // same percentage on either platform.
  it("shows how far along the profile is, and moves as it is filled", () => {
    // USER has 8 of 10: no address, no intents.
    renderEditor();
    expect(screen.getByTestId("edit-completion-percent")).toHaveTextContent("80%");
    expect(screen.getByRole("progressbar")).toHaveAttribute("aria-valuenow", "80");

    fireEvent.click(screen.getByTestId("edit-intent-learn"));
    expect(screen.getByTestId("edit-completion-percent")).toHaveTextContent("90%");
  });

  it("takes the address from the loaded document, which the form cannot edit", () => {
    renderEditor({ data: { ...USER, location: { city: "Seoul" } } });
    expect(screen.getByTestId("edit-completion-percent")).toHaveTextContent("90%");
  });

  it("gets out of the way at 100%", () => {
    renderEditor({ data: { ...USER, location: { city: "Seoul" }, intents: ["learn"] } });
    expect(screen.queryByTestId("edit-completion")).not.toBeInTheDocument();
  });
});

describe("saving", () => {
  it("keeps Save disabled until something actually changes", () => {
    renderEditor();
    expect(screen.getByTestId("edit-save")).toBeDisabled();

    fireEvent.change(screen.getByTestId("edit-occupation"), {
      target: { name: "occupation", value: "Teacher" },
    });
    expect(screen.getByTestId("edit-save")).not.toBeDisabled();
  });

  it("goes clean again when an edit is undone", () => {
    renderEditor();
    const bio = screen.getByTestId("edit-bio");
    fireEvent.change(bio, { target: { name: "bio", value: "Hello!" } });
    expect(screen.getByTestId("edit-save")).not.toBeDisabled();

    fireEvent.change(bio, { target: { name: "bio", value: "Hello" } });
    expect(screen.getByTestId("edit-save")).toBeDisabled();
  });

  it("sends the edited fields, gender lowercased, and leaves for the profile", async () => {
    renderEditor();
    fireEvent.change(screen.getByTestId("edit-school"), {
      target: { name: "school", value: "SNU" },
    });
    fireEvent.click(screen.getByTestId("edit-level-C1"));
    fireEvent.click(screen.getByTestId("edit-topic-travel"));
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1));
    const payload = mockUpdate.mock.calls[0][0];
    // Neither the level nor the school belongs in this body — the endpoint
    // discards both.
    expect(payload.languageLevel).toBeUndefined();
    expect(payload.school).toBeUndefined();
    expect(mockUpdateUserById).toHaveBeenCalledWith({
      id: "me",
      body: { languageLevel: "C1", school: "SNU" },
    });
    expect(payload.topics).toEqual(["music", "travel"]);
    expect(payload.gender).toBe("female");
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith("/profile"));
  });

  it("posts exactly the owned fields — never image, images or createdAt", async () => {
    renderEditor({
      // The API document carries fields the editor neither shows nor owns.
      data: { ...USER, image: "avatar.jpg", images: ["raw.jpg"], createdAt: "2025-01-01" },
    });
    fireEvent.change(screen.getByTestId("edit-name"), {
      target: { name: "name", value: "Ada L" },
    });
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1));
    expect(Object.keys(mockUpdate.mock.calls[0][0]).sort()).toEqual(
      [
        "_id",
        "bio",
        "birth_day",
        "birth_month",
        "birth_year",
        "email",
        "gender",
        "imageUrls",
        "language_to_learn",
        "name",
        "native_language",
        "topics",
        "username",
      ].sort()
    );
  });

  // `PUT /auth/updatedetails` destructures a fixed list of field names and
  // builds its update from exactly those. MBTI, blood type, occupation and
  // school are not on it, so the editor could collect them, send them, show
  // "Profile updated successfully" and change nothing at all. They go where
  // the app sends them, and where the CEFR level already went.
  it.each(["mbti", "bloodType", "occupation", "school"])(
    "saves %s through the endpoint that accepts it, not the one that drops it",
    async (field) => {
      const edit: Record<string, () => void> = {
        mbti: () => fireEvent.click(screen.getByTestId("edit-mbti-ENFP")),
        bloodType: () => fireEvent.click(screen.getByTestId("edit-blood-O")),
        occupation: () =>
          fireEvent.change(screen.getByTestId("edit-occupation"), {
            target: { name: "occupation", value: "Teacher" },
          }),
        school: () =>
          fireEvent.change(screen.getByTestId("edit-school"), {
            target: { name: "school", value: "SNU" },
          }),
      };
      const expected: Record<string, string> = {
        mbti: "ENFP",
        bloodType: "O",
        occupation: "Teacher",
        school: "SNU",
      };

      renderEditor();
      edit[field]();
      fireEvent.click(screen.getByTestId("edit-save"));

      await waitFor(() => expect(mockUpdateUserById).toHaveBeenCalledTimes(1));
      expect(mockUpdateUserById).toHaveBeenCalledWith({
        id: "me",
        body: { [field]: expected[field] },
      });
      expect(mockUpdate.mock.calls[0][0][field]).toBeUndefined();
    }
  );

  // Why someone is here: learn / meet / date. Stored on the user and ranked on
  // in lib/matchIntent.js, and the web had no control for it at all — every
  // web-registered account sat on the default [] for good while app users
  // could set theirs.
  describe("intents", () => {
    it("fills the toggles from the loaded document", () => {
      renderEditor({ data: { ...USER, intents: ["meet"] } });
      expect(screen.getByTestId("edit-intent-meet")).toHaveAttribute(
        "aria-pressed",
        "true"
      );
      expect(screen.getByTestId("edit-intent-learn")).toHaveAttribute(
        "aria-pressed",
        "false"
      );
    });

    it("saves them through the endpoint that accepts them", async () => {
      renderEditor();
      fireEvent.click(screen.getByTestId("edit-intent-learn"));
      fireEvent.click(screen.getByTestId("edit-save"));

      await waitFor(() => expect(mockUpdateUserById).toHaveBeenCalledTimes(1));
      expect(mockUpdateUserById).toHaveBeenCalledWith({
        id: "me",
        body: { intents: ["learn"] },
      });
      expect(mockUpdate.mock.calls[0][0].intents).toBeUndefined();
    });

    it("stores the canonical order, not the order they were tapped", async () => {
      renderEditor();
      fireEvent.click(screen.getByTestId("edit-intent-date"));
      fireEvent.click(screen.getByTestId("edit-intent-learn"));
      fireEvent.click(screen.getByTestId("edit-save"));

      await waitFor(() => expect(mockUpdateUserById).toHaveBeenCalledTimes(1));
      expect(mockUpdateUserById.mock.calls[0][0].body.intents).toEqual([
        "learn",
        "date",
      ]);
    });

    it("turns one off again", async () => {
      renderEditor({ data: { ...USER, intents: ["learn", "meet"] } });
      fireEvent.click(screen.getByTestId("edit-intent-meet"));
      fireEvent.click(screen.getByTestId("edit-save"));

      await waitFor(() => expect(mockUpdateUserById).toHaveBeenCalledTimes(1));
      expect(mockUpdateUserById.mock.calls[0][0].body.intents).toEqual(["learn"]);
    });

    it("counts as a change, and as no change when put back", () => {
      renderEditor({ data: { ...USER, intents: ["learn"] } });
      expect(screen.getByTestId("edit-save")).toBeDisabled();

      fireEvent.click(screen.getByTestId("edit-intent-meet"));
      expect(screen.getByTestId("edit-save")).not.toBeDisabled();

      fireEvent.click(screen.getByTestId("edit-intent-meet"));
      expect(screen.getByTestId("edit-save")).toBeDisabled();
    });

    it("resends nothing when the intents were never touched", async () => {
      renderEditor({ data: { ...USER, intents: ["learn"] } });
      fireEvent.change(screen.getByTestId("edit-bio"), {
        target: { name: "bio", value: "Hi there" },
      });
      fireEvent.click(screen.getByTestId("edit-save"));

      await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1));
      expect(mockUpdateUserById).not.toHaveBeenCalled();
    });

    it("offers dating to a known adult", () => {
      renderEditor();
      expect(screen.getByTestId("edit-intent-date")).toBeInTheDocument();
    });

    it.each([
      ["a minor", { birth_year: "2015", birth_month: "1", birth_day: "1" }],
      ["an unknown age", { birth_year: "", birth_month: "", birth_day: "" }],
    ])("withholds dating from %s", (unused, birth) => {
      // sanitizeIntents strips `date` on the write for anyone who is not a
      // KNOWN adult, so offering the choice would mean offering one the server
      // is about to discard.
      renderEditor({ data: { ...USER, ...birth } });
      expect(screen.queryByTestId("edit-intent-date")).not.toBeInTheDocument();
      expect(screen.getByTestId("edit-intent-learn")).toBeInTheDocument();
      expect(screen.getByTestId("edit-intent-meet")).toBeInTheDocument();
    });

    it("says what stays private, because a promise nobody sees cannot be acted on", () => {
      renderEditor();
      expect(screen.getByTestId("edit-intent-note")).toBeInTheDocument();
    });
  });

  it("sends one request for everything that endpoint owns, not one each", async () => {
    renderEditor();
    fireEvent.click(screen.getByTestId("edit-level-C1"));
    fireEvent.click(screen.getByTestId("edit-mbti-ENFP"));
    fireEvent.change(screen.getByTestId("edit-occupation"), {
      target: { name: "occupation", value: "Teacher" },
    });
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockUpdateUserById).toHaveBeenCalledTimes(1));
    expect(mockUpdateUserById).toHaveBeenCalledWith({
      id: "me",
      body: { languageLevel: "C1", mbti: "ENFP", occupation: "Teacher" },
    });
  });

  it("skips the second request entirely when none of its fields moved", async () => {
    renderEditor();
    fireEvent.change(screen.getByTestId("edit-bio"), {
      target: { name: "bio", value: "Hi there" },
    });
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1));
    expect(mockUpdateUserById).not.toHaveBeenCalled();
  });

  it("puts the fields back when the second request is rejected", async () => {
    // The first call already persisted. Reporting the whole save as failed
    // would tell someone nothing stuck when everything but these four did —
    // but the form must not go on claiming a value the server never took.
    mockUpdateUserById.mockReturnValue(rejected());
    renderEditor();
    fireEvent.change(screen.getByTestId("edit-occupation"), {
      target: { name: "occupation", value: "Teacher" },
    });
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockToastSuccess).toHaveBeenCalled());
    expect(mockToastError).toHaveBeenCalled();
    expect((screen.getByTestId("edit-occupation") as HTMLInputElement).value).toBe(
      "Engineer"
    );
  });

  it("persists a changed CEFR level through the endpoint that accepts it", async () => {
    renderEditor();
    fireEvent.click(screen.getByTestId("edit-level-C1"));
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockUpdateUserById).toHaveBeenCalledTimes(1));
    expect(mockUpdateUserById).toHaveBeenCalledWith({
      id: "me",
      body: { languageLevel: "C1" },
    });
    // /auth/updatedetails does not whitelist it, so it is not sent there.
    expect(mockUpdate.mock.calls[0][0].languageLevel).toBeUndefined();
  });

  // The 17 fields are already persisted by the time the level call runs, so a
  // rejection there must not report the whole save as failed.
  it("still reports success when only the level call is rejected", async () => {
    mockUpdateUserById.mockReturnValue(rejected());
    renderEditor();
    fireEvent.click(screen.getByTestId("edit-level-C1"));
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockToastSuccess).toHaveBeenCalledTimes(1));
    // A secondary, non-blocking message about the level alone.
    expect(mockToastError).toHaveBeenCalledTimes(1);
    expect(mockNavigate).toHaveBeenCalledWith("/profile");
  });

  it("leaves an unmoved level out of the body its endpoint does receive", async () => {
    renderEditor();
    fireEvent.change(screen.getByTestId("edit-school"), {
      target: { name: "school", value: "SNU" },
    });
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockUpdateUserById).toHaveBeenCalledTimes(1));
    const body = mockUpdateUserById.mock.calls[0][0].body;
    expect(body).toEqual({ school: "SNU" });
    expect("languageLevel" in body).toBe(false);
  });

  it("stays on the form and says so when the save is rejected", async () => {
    mockUpdate.mockReturnValue(rejected());
    renderEditor();
    fireEvent.change(screen.getByTestId("edit-name"), {
      target: { name: "name", value: "Ada L" },
    });
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(mockToastError).toHaveBeenCalled());
    expect(mockNavigate).not.toHaveBeenCalled();
    expect(screen.getByTestId("edit-save")).not.toBeDisabled();
  });
});

describe("photos", () => {
  it("uploads the chosen files against the signed-in user", async () => {
    const { container } = renderEditor();
    const input = container.querySelector(
      '[data-testid="edit-photo-add"] input'
    ) as HTMLInputElement;
    const file = new File(["x"], "me.png", { type: "image/png" });
    fireEvent.change(input, { target: { files: [file] } });

    await waitFor(() => expect(mockUpload).toHaveBeenCalledTimes(1));
    expect(mockUpload.mock.calls[0][0].userId).toBe("me");
    expect(mockUpload.mock.calls[0][0].imageFiles).toBeInstanceOf(FormData);
  });

  it("hides the add tile once the limit is reached", () => {
    const full = ["1", "2", "3", "4", "5", "6"].map((n) => `https://cdn.test/${n}.jpg`);
    renderEditor({ data: { ...USER, imageUrls: full } });
    expect(screen.getAllByTestId("edit-photo")).toHaveLength(6);
    expect(screen.queryByTestId("edit-photo-add")).not.toBeInTheDocument();
  });

  it("deletes a photo only after the confirmation is accepted", async () => {
    renderEditor();
    fireEvent.click(screen.getByTestId("edit-photo-delete-1"));
    expect(screen.getByTestId("confirm-dialog")).toBeInTheDocument();
    expect(mockDeletePhoto).not.toHaveBeenCalled();

    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    await waitFor(() =>
      expect(mockDeletePhoto).toHaveBeenCalledWith({ userId: "me", index: 1 })
    );
  });

  it("keeps the dialog open with the failure when the delete is rejected", async () => {
    mockDeletePhoto.mockReturnValue(rejected());
    renderEditor();
    fireEvent.click(screen.getByTestId("edit-photo-delete-0"));
    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));

    await waitFor(() =>
      expect(screen.getByTestId("confirm-dialog-error")).toBeInTheDocument()
    );
    expect(screen.getByTestId("confirm-dialog")).toBeInTheDocument();
  });
});

describe("unsaved changes", () => {
  it("lets a clean form leave without a word", async () => {
    renderEditor();
    fireEvent.click(screen.getByTestId("edit-cancel"));
    await waitFor(() => expect(screen.getByTestId("profile-screen")).toBeInTheDocument());
  });

  it("stops a dirty form leaving, and stays put when the edit is kept", async () => {
    renderEditor();
    fireEvent.change(screen.getByTestId("edit-name"), {
      target: { name: "name", value: "Ada L" },
    });
    fireEvent.click(screen.getByTestId("edit-cancel"));

    await waitFor(() => expect(screen.getByTestId("confirm-dialog")).toBeInTheDocument());
    expect(screen.queryByTestId("profile-screen")).not.toBeInTheDocument();

    fireEvent.click(screen.getByTestId("confirm-dialog-cancel"));
    await waitFor(() =>
      expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument()
    );
    expect(screen.getByTestId("edit-basics")).toBeInTheDocument();
  });

  it("leaves once the changes are discarded", async () => {
    renderEditor();
    fireEvent.change(screen.getByTestId("edit-name"), {
      target: { name: "name", value: "Ada L" },
    });
    fireEvent.click(screen.getByTestId("edit-cancel"));
    await waitFor(() => expect(screen.getByTestId("confirm-dialog")).toBeInTheDocument());

    fireEvent.click(screen.getByTestId("confirm-dialog-confirm"));
    await waitFor(() => expect(screen.getByTestId("profile-screen")).toBeInTheDocument());
  });

  it("does not block the redirect the save itself performs", async () => {
    // No useNavigate stub here: the save drives the real router, past the
    // guard, with the form still dirty at the moment navigate() is called.
    mockNavigation = false;
    renderEditor();
    fireEvent.change(screen.getByTestId("edit-name"), {
      target: { name: "name", value: "Ada L" },
    });
    fireEvent.click(screen.getByTestId("edit-save"));

    await waitFor(() => expect(screen.getByTestId("profile-screen")).toBeInTheDocument());
    expect(screen.queryByTestId("confirm-dialog")).not.toBeInTheDocument();
  });

  it("warns before the tab is closed only while there are changes", () => {
    const add = jest.spyOn(window, "addEventListener");
    renderEditor();
    expect(add.mock.calls.filter((call) => call[0] === "beforeunload")).toHaveLength(0);

    fireEvent.change(screen.getByTestId("edit-name"), {
      target: { name: "name", value: "Ada L" },
    });
    expect(
      add.mock.calls.filter((call) => call[0] === "beforeunload").length
    ).toBeGreaterThan(0);
    add.mockRestore();
  });
});
