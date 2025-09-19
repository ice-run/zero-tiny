export type No = {
  no?: string;
};

export type Ok = {
  ok?: string;
};

export type Request<P> = {
  param: P;
};

export type Response<D> = {
  /** code 响应编码，6 位数字字符串 */
  code: string;
  /** message 响应信息，字符串 */
  message: string;
  data: D;
};

export type PageParam<P> = {
  /** 页码 页码，>= 1 ，起始页 = 1 */
  page?: number;
  /** 步长 分页步长，> 0 */
  size?: number;
  /** 查询参数 */
  param?: P;
  /** 匹配模式列表 */
  matches?: Array<Match>;
  /** 排序条件列表 */
  orders?: Array<Order>;
};

export type PageData<D> = {
  /** 页码 页码，>= 1 ，起始页 = 1 */
  page?: number;
  /** 步长 分页步长，> 0 */
  size?: number;
  /** 总数 所有分页的总条数 */
  total?: number;
  /** 表头 键值对儿 */
  head?: Map<string, string>;
  /** 列表 数据列表 */
  list?: Array<D>;
};

export type Match = {
  /** 匹配字段 */
  property: string;
  /** 匹配模式 */
  mode: "EXACT" | "CONTAIN" | "REGEX";
};

export type Order = {
  /** 排序字段 */
  property: string;
  /** 排序方式 */
  direction: "ASC" | "DESC";
};

export type IdParam = {
  /** id ID */
  id: string;
};
