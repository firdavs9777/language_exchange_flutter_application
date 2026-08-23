import "@testing-library/jest-dom";
import { render, screen, fireEvent } from "@testing-library/react";
import PhotoGrid from "./PhotoGrid";

const images = ["a.png", "b.png", "c.png"];

it("renders one tile per image", () => {
  render(<PhotoGrid images={images} mode="view" />);
  expect(screen.getAllByTestId("photo-tile")).toHaveLength(3);
});

it("view mode does not show delete buttons or the add tile", () => {
  render(<PhotoGrid images={images} mode="view" />);
  expect(screen.queryByTestId("photo-delete-0")).not.toBeInTheDocument();
  expect(screen.queryByTestId("photo-add")).not.toBeInTheDocument();
});

it("edit mode shows delete buttons and calls onDelete with the index", () => {
  const onDelete = jest.fn();
  render(<PhotoGrid images={images} mode="edit" onDelete={onDelete} />);
  expect(screen.getByTestId("photo-add")).toBeInTheDocument();
  fireEvent.click(screen.getByTestId("photo-delete-1"));
  expect(onDelete).toHaveBeenCalledWith(1);
});

it("edit mode calls onAdd with the selected file", () => {
  const onAdd = jest.fn();
  const { container } = render(<PhotoGrid images={images} mode="edit" onAdd={onAdd} />);
  const input = container.querySelector('input[type="file"]') as HTMLInputElement;
  const file = new File(["x"], "photo.png", { type: "image/png" });
  fireEvent.change(input, { target: { files: [file] } });
  expect(onAdd).toHaveBeenCalledWith(file);
});
