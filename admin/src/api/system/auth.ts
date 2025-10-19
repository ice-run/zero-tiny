import { http } from "@/utils/http";
import type { No, Ok, Request, Response } from "@/api";
import type { LoginParam, TokenData } from "@/api/system";

/** 登录 传入 username & password 信息，获取 token POST /api/login */
export async function login(
  request: Request<LoginParam>
): Promise<Response<TokenData>> {
  return http.post<Request<LoginParam>, Response<TokenData>>(`/api/login`, {
    data: request
  });
}

/** 退出 header 中传入 token 信息，退出登录 POST /api/logout */
export async function logout(request: Request<No>): Promise<Response<Ok>> {
  return http.post<Request<No>, Response<Ok>>(`/api/logout`, {
    data: request
  });
}
