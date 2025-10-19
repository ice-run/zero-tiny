import { http } from "@/utils/http";
import type { No, PageData, PageParam, Request, Response } from "@/api";
import type {
  UserData,
  UserSearch,
  UserSelect,
  UserUpdate,
  UserUpsert
} from "@/api/system";

/** 用户信息 header 中传入 token 信息，获取用户信息 POST /api/user-info */
export async function userInfo(
  request: Request<No>
): Promise<Response<UserData>> {
  return http.post<Request<No>, Response<UserData>>(`/api/user-info`, {
    data: request
  });
}

/** 用户更新自己的信息 POST /api/user-update */
export async function userUpdate(
  request: Request<UserUpdate>
): Promise<Response<UserData>> {
  return http.post<Request<UserUpdate>, Response<UserData>>(
    `/api/user-update`,
    { data: request }
  );
}

/** 查询用户 传入 id 查询用户信息 POST /api/user-select */
export async function userSelect(
  request: Request<UserSelect>
): Promise<Response<UserData>> {
  return http.post<Request<UserSelect>, Response<UserData>>(
    `/api/user-select`,
    { data: request }
  );
}

/** 写入用户 传入用户信息，新增或更新一个用户 POST /api/user-upsert */
export async function userUpsert(
  request: Request<UserUpsert>
): Promise<Response<UserData>> {
  return http.post<Request<UserUpsert>, Response<UserData>>(
    `/api/user-upsert`,
    { data: request }
  );
}

/** 搜索用户 传入用户信息，搜索用户列表 POST /api/user-search */
export async function userSearch(
  request: Request<PageParam<UserSearch>>
): Promise<Response<PageData<UserData>>> {
  return http.post<
    Request<PageParam<UserSearch>>,
    Response<PageData<UserData>>
  >(`/api/user-search`, { data: request });
}
