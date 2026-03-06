export declare const FeishuTaskSchema: import("@sinclair/typebox").TObject<{
  action: import("@sinclair/typebox").TUnsafe<
    | "update"
    | "get"
    | "create"
    | "list"
    | "complete"
    | "add_members"
    | "add_reminder"
    | "add_comment"
  >;
  summary: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  description: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  due: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  members: import("@sinclair/typebox").TOptional<
    import("@sinclair/typebox").TArray<
      import("@sinclair/typebox").TObject<{
        id: import("@sinclair/typebox").TString;
        role: import("@sinclair/typebox").TOptional<
          import("@sinclair/typebox").TUnsafe<"assignee" | "follower">
        >;
      }>
    >
  >;
  task_guid: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  member_ids: import("@sinclair/typebox").TOptional<
    import("@sinclair/typebox").TArray<import("@sinclair/typebox").TString>
  >;
  role: import("@sinclair/typebox").TOptional<
    import("@sinclair/typebox").TUnsafe<"assignee" | "follower">
  >;
  relative_fire_minutes: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TNumber>;
  page_size: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TNumber>;
  page_token: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  sender_open_id: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
  content: import("@sinclair/typebox").TOptional<import("@sinclair/typebox").TString>;
}>;
//# sourceMappingURL=task-schema.d.ts.map
