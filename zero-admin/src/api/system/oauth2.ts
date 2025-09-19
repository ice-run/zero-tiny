import { http } from "@/utils/http";
import type { No, Ok, Request, Response } from "@/api";
import type { LoginParam, TokenData } from "@/api/system";

/** 登录 传入 username & password 信息，获取 token POST /api/oauth2/login */
export async function oauth2Login(
  request: Request<LoginParam>
): Promise<Response<TokenData>> {
  return http.post<Request<LoginParam>, Response<TokenData>>(
    `/api/oauth2/login`,
    {
      data: request
    }
  );
}

/** 退出 header 中传入 token 信息，退出登录 POST /api/oauth2/logout */
export async function oauth2Logout(
  request: Request<No>
): Promise<Response<Ok>> {
  return http.post<Request<No>, Response<Ok>>(`/api/oauth2/logout`, {
    data: request
  });
}
