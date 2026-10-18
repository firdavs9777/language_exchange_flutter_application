import "@testing-library/jest-dom";
import React from "react";
import { render, screen, fireEvent } from "@testing-library/react";
import DataTable from "./DataTable";

jest.mock("react-i18next", () => ({ useTranslation: () => ({ t: () => "" }) }));

const columns = [
  { key: "name", header: "Name" },
  { key: "email", header: "Email" },
  { key: "taps", header: "Taps", render: (row: any) => <b>{row.taps * 2}</b> },
];

const rows = [
  { id: "1", name: "Ada", email: "ada@example.com", taps: 3 },
  { id: "2", name: "Grace", email: "grace@example.com", taps: 4 },
];

it("renders a header per column and a row per record", () => {
  render(<DataTable columns={columns} rows={rows} rowKey="id" />);
  expect(screen.getByText("Name")).toBeInTheDocument();
  expect(screen.getByText("Email")).toBeInTheDocument();
  expect(screen.getAllByTestId("data-row")).toHaveLength(2);
  expect(screen.getByText("Ada")).toBeInTheDocument();
  expect(screen.getByText("grace@example.com")).toBeInTheDocument();
});

it("uses a column's render function for its cell", () => {
  render(<DataTable columns={columns} rows={rows} rowKey="id" />);
  expect(screen.getByText("6")).toBeInTheDocument();
  expect(screen.getByText("8")).toBeInTheDocument();
});

it("shows the empty text instead of rows when there are none", () => {
  render(<DataTable columns={columns} rows={[]} rowKey="id" emptyText="No taps yet" />);
  expect(screen.queryAllByTestId("data-row")).toHaveLength(0);
  expect(screen.getByText("No taps yet")).toBeInTheDocument();
});

it("calls onRowClick with the clicked row", () => {
  const onRowClick = jest.fn();
  render(<DataTable columns={columns} rows={rows} rowKey="id" onRowClick={onRowClick} />);
  fireEvent.click(screen.getAllByTestId("data-row")[1]);
  expect(onRowClick).toHaveBeenCalledWith(rows[1]);
});

it("accepts a function rowKey", () => {
  render(<DataTable columns={columns} rows={rows} rowKey={(row: any) => row.email} />);
  expect(screen.getAllByTestId("data-row")).toHaveLength(2);
});

it("renders no pagination controls without onPageChange", () => {
  render(<DataTable columns={columns} rows={rows} rowKey="id" />);
  expect(screen.queryByTestId("data-table-next")).not.toBeInTheDocument();
});

it("pages forward and back through onPageChange", () => {
  const onPageChange = jest.fn();
  render(
    <DataTable columns={columns} rows={rows} rowKey="id" page={2} hasMore onPageChange={onPageChange} />
  );
  fireEvent.click(screen.getByTestId("data-table-next"));
  expect(onPageChange).toHaveBeenCalledWith(3);
  fireEvent.click(screen.getByTestId("data-table-prev"));
  expect(onPageChange).toHaveBeenCalledWith(1);
});

it("disables previous on the first page and next on the last", () => {
  render(
    <DataTable
      columns={columns}
      rows={rows}
      rowKey="id"
      page={1}
      hasMore={false}
      onPageChange={jest.fn()}
    />
  );
  expect(screen.getByTestId("data-table-prev")).toBeDisabled();
  expect(screen.getByTestId("data-table-next")).toBeDisabled();
});

// The sr-only labels inside cells are position:absolute. Without a positioned
// scroller their containing block is the page, they escape `overflow-x: auto`,
// and a wide table stretches the document instead of scrolling inside its own
// box -- which `body { overflow-x: hidden }` then clips away on a phone.
it("positions the horizontal scroller so absolute cell content is clipped with it", () => {
  const { container } = render(
    <DataTable
      rows={[{ id: "1", a: "x" }]}
      rowKey="id"
      columns={[{ key: "a", header: "A" }]}
    />
  );
  const scroller = container.querySelector(".overflow-x-auto") as HTMLElement;
  expect(scroller).toBeInTheDocument();
  expect(scroller.className).toContain("relative");
});
