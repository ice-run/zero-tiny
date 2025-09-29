import axios from "axios";
import { message } from "@/utils/message";
import { formatToken, getToken } from "@/utils/auth";

import type { Request, Response } from "@/api";
import type { FileData, FileParam } from "@/api/file";
import { radixConvert } from "@/utils/zero";

export const uploadUri = "/server/api/file/upload";
export const downloadUri = "/server/api/file/download";
export const viewUri = "/server/api/file/view";

export async function upload(file: File): Promise<Response<FileData>> {
  const token = getToken();

  // 检查文件类型是否为图片
  const isImage = file.type.startsWith("image/");

  let processedFile = file;

  if (isImage && file.size > 1024 * 1024) {
    // 1MB
    try {
      processedFile = await compressImageUntilUnderSize(file);
    } catch (error) {
      console.error("Error compressing image:", error);
      return Promise.reject(new Error("图片压缩失败"));
    }
  }
  // let blobURL = URL.createObjectURL(processedFile);
  // console.log("🚀 ~ blobURL:", blobURL);
  return await axios
    .post(
      uploadUri,
      {
        file: processedFile
      },
      {
        headers: {
          "Content-Type": "multipart/form-data",
          Authorization: formatToken(token)
        }
      }
    )
    .then(({ data }) => {
      const response: Response<FileData> = {
        code: data.code,
        message: data.message,
        data: data.data
      };
      if (response.code === "0000") {
        message("上传成功", { type: "success" });
        return response;
      } else {
        message(data.message, { type: "error" });
        return Promise.reject(response);
      }
    })
    .catch(error => {
      console.error(error);
      return Promise.reject(error);
    });
}

// 压缩图片的函数
async function compressImageUntilUnderSize(
  file: File,
  maxSizeInBytes: number = 1024 * 1024,
  qualityReductionStep: number = 0.1
): Promise<File> {
  let currentFile = file;
  let quality = 0.7;

  while (currentFile.size > maxSizeInBytes && quality > 0.1) {
    // 压缩图片
    currentFile = await compressImage(file, 800, 600, quality);
    quality -= qualityReductionStep;
  }

  if (currentFile.size > maxSizeInBytes) {
    throw new Error("无法将图片压缩到 1MB 以内");
  }

  return currentFile;
}
export function compressImage(
  file: File,
  maxWidth: number,
  maxHeight: number,
  quality: number = 0.7
): Promise<File> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = event => {
      const img = new Image();
      img.onload = () => {
        let width = img.width;
        let height = img.height;

        // Calculate the new dimensions to maintain aspect ratio
        if (width > height) {
          if (width > maxWidth) {
            height *= maxWidth / width;
            width = maxWidth;
          }
        } else {
          if (height > maxHeight) {
            width *= maxHeight / height;
            height = maxHeight;
          }
        }

        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext("2d");
        if (!ctx) {
          reject(new Error("Canvas context not available"));
          return;
        }
        ctx.drawImage(img, 0, 0, width, height);

        canvas.toBlob(
          blob => {
            if (blob) {
              resolve(new File([blob], file.name, { type: file.type }));
            } else {
              reject(new Error("Failed to create blob"));
            }
          },
          file.type,
          quality
        );
      };
      img.onerror = error => {
        reject(error);
      };
      img.src = event.target?.result as string;
    };
    reader.onerror = error => {
      reject(error);
    };
    reader.readAsDataURL(file);
  });
}

export async function download(request: Request<FileParam>): Promise<void> {
  const token = getToken();
  const param = request.param;
  await axios
    .post(
      downloadUri,
      {
        param: param
      },
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: formatToken(token)
        },
        responseType: "blob"
      }
    )
    .then(response => {
      output(response);
    })
    .catch(error => {
      console.error(error);
      return Promise.reject(error);
    });
}

/**
 * 下载 response blob
 * @param response
 */
export function output(response: any): void {
  const disposition = response.headers.get("content-disposition");
  console.debug(disposition);
  if (!disposition) {
    throw new Error();
  }
  const dis = disposition.split(";");
  let filename: string;
  for (let d of dis) {
    d = d.trim();
    if (d.startsWith("filename=")) {
      filename = d;
    }
  }
  if (!filename) {
    throw new Error();
  }
  const fn = filename.split("=");
  let name = fn[1];
  if (name.startsWith('"') && name.endsWith('"')) {
    name = name.substring(1, name.length - 1);
  }
  name = decodeURI(name);
  const blob = new Blob([response.data]);
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.style.display = "none";
  a.href = url;
  a.download = name;
  a.click();
  window.URL.revokeObjectURL(url);
  a.remove();
}

export function fetch(name: string, url: string): void {
  const a = document.createElement("a");
  a.style.display = "none";
  a.href = url;
  a.target = "_blank";
  a.download = name;
  a.click();
  window.URL.revokeObjectURL(url);
  a.remove();
}

export function fileUrl(param: FileParam) {
  if (!param || (!param.id && !param.code)) {
    return "";
  }
  let id: string = param.id;
  let code: string = param.code;
  if (id && !code) {
    code = radixConvert(id, 10, 62) as string;
  } else if (!id && code) {
    id = radixConvert(code, 62, 10) as string;
  } else {
    const c = radixConvert(id, 10, 62) as string;
    if (c !== code) {
      console.error("id and code not match");
      return "";
    }
  }
  return viewUri + "?" + "id=" + id + "&" + "code=" + code;
}
