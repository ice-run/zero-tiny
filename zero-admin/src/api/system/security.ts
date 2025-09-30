import { http } from "@/utils/http";
import type { Ok, Request, Response } from "@/api";
import type { ChangePassword, ResetPassword } from "@/api/system";

/** 变更密码 输入 新密码和旧密码，设置用户密码 POST /api/change-password */
export async function changePassword(
  request: Request<ChangePassword>
): Promise<Response<Ok>> {
  return http.post<Request<ChangePassword>, Response<Ok>>(
    `/api/change-password`,
    { data: request }
  );
}

/** 重置密码 输入 用户 id 和 密码，重新设置密码 POST /api/reset-password */
export async function resetPassword(
  request: Request<ResetPassword>
): Promise<Response<Ok>> {
  return http.post<Request<ResetPassword>, Response<Ok>>(
    `/api/reset-password`,
    { data: request }
  );
}
