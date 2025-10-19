import { http } from "@/utils/http";
import type { Request, Response } from "@/api";
import type { FileData, FileParam } from "@/api/file";

/** info 文件信息 传入文件 id，查询文件信息 POST /api/file-info */
export async function info(
  request: Request<FileParam>
): Promise<Response<FileData>> {
  return http.post<Request<FileParam>, Response<FileData>>(`/api/file-info`, {
    data: request
  });
}
