import { useEffect, useMemo, useState } from "react";
import { useGetCommunityMembersQuery } from "../../../store/slices/communitySlice";

export function languageMatchParams(me: any): { [k: string]: string } {
  if (me && me.native_language && me.language_to_learn) {
    return { nativeLanguage: String(me.native_language), learningLanguage: String(me.language_to_learn), matchLanguage: "true" };
  }
  return {};
}

/** Pages of 20 from GET /auth/users for one fixed filter; resets when it changes. */
export function useMemberPages(params: { [k: string]: string | undefined } | null) {
  const key = JSON.stringify(params || null);
  const [page, setPage] = useState(1);
  const [members, setMembers] = useState<any[]>([]);
  useEffect(() => {
    setPage(1);
    setMembers([]);
  }, [key]);
  const arg = useMemo(() => (params ? Object.assign({ page, limit: 20 }, params) : { page: 1, limit: 20 }), [key, page]); // eslint-disable-line react-hooks/exhaustive-deps
  const { data, isLoading, isError, isFetching, refetch } = useGetCommunityMembersQuery(arg, { skip: !params });
  const rows: any[] = (data && Array.isArray(data.data) ? data.data : []) as any[];
  // Merge on what the page contains, not on object identity: a re-delivered
  // page with the same members must not re-render forever.
  const rowsKey = rows.map((m: any) => (m && m._id) || "").join(",");
  useEffect(() => {
    if (!params) return;
    setMembers((prev) => {
      const seen: { [id: string]: boolean } = {};
      const out: any[] = [];
      (page === 1 ? [] : prev).concat(rows).forEach((m: any) => {
        if (m && m._id && !seen[m._id]) {
          seen[m._id] = true;
          out.push(m);
        }
      });
      return out;
    });
  }, [rowsKey, page, key]); // eslint-disable-line react-hooks/exhaustive-deps
  return {
    members: params ? (members.length || page > 1 ? members : rows) : [],
    isLoading: !!params && !!isLoading,
    isError: !!params && !!isError,
    hasMore: !!params && rows.length === 20 && !isFetching,
    loadMore: () => setPage((p) => p + 1),
    refetch,
  };
}
