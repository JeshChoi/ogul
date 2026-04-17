import type { Scan, UserAnalytics } from "@/types";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body?.error?.message ?? `Request failed: ${res.status}`);
  }

  return res.json() as Promise<T>;
}

export const api = {
  health: () => request<{ status: string; version: string }>("/health"),

  createScan: (payload: { userId: string; capturedAt: string; notes?: string }) =>
    request<Scan>("/scans", {
      method: "POST",
      body: JSON.stringify(payload),
    }),

  getScan: (id: string) => request<Scan>(`/scans/${id}`),

  getUserScans: (userId: string) =>
    request<{ userId: string; total: number; scans: Scan[] }>(`/users/${userId}/scans`),

  getUserAnalytics: (userId: string) =>
    request<UserAnalytics>(`/users/${userId}/analytics`),
};
