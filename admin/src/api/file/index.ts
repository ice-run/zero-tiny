export type FileData = {
  /** id id */
  id: string;
  /** code 文件 code */
  code: string;
  /** name 文件名 */
  name: string;
  /** origin 源文件名 */
  origin: string;
  /** type 文件类型 */
  type: string;
  /** size 文件大小 */
  size: string;
  /** path 路径 */
  path: string;
};

export type FileParam = {
  /** id 文件 ID */
  id: string;
  /** code 文件 code */
  code?: string;
};
