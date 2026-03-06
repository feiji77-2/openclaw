export declare const FeishuSheetsSchema: import("@sinclair/typebox").TObject<{
  action: import("@sinclair/typebox").TUnsafe<
    | "append"
    | "get_meta"
    | "read_range"
    | "write_range"
    | "insert_rows"
    | "add_sheet"
    | "list_sheets"
  >;
  spreadsheet_token: import("@sinclair/typebox").TString;
  range: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  values: import("@sinclair/typebox").TOptional<
    import("@sinclair/typebox").TArray<
      import("@sinclair/typebox").TArray<import("@sinclair/typebox").TAny>
    >
  >;
  sheet_id: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  start_index: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TNumber>;
  count: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TNumber>;
  title: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  index: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TNumber>;
}>;
//# sourceMappingURL=sheets-schema.d.ts.map
