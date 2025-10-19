export type LoginParam = {
  /** username */
  username: string;
  /** password */
  password: string;
};

export type TokenData = {
  /** token */
  token: string;
};

export type UserData = {
  /** username */
  username: string;
  /** nickname */
  nickname?: string;
  /** avatar */
  avatar?: string;
};

export type UserSearch = {
  /** ID 用户 ID */
  id?: string;
  /** username 用户名 */
  username?: string;
  /** nickname 昵称 */
  nickname?: string;
  /** valid 是否有效 */
  valid?: boolean;
};

export type UserSelect = {
  /** ID 用户 ID */
  id: string;
};

export type UserUpsert = {
  /** ID 用户 ID */
  id?: string;
  /** 用户名 仅用于用户标识，不包含任何实际业务信息 */
  username?: string;
  /** valid 是否有效 */
  valid?: boolean;
};

export type UserUpdate = {
  nickname?: string;
  avatar?: string;
};

export type ResetPassword = {
  /** id user id */
  id: string;
  /** 密码 如果不传此字段，将使用用户名作为默认密码 */
  password?: string;
};

export type ChangePassword = {
  /** oldPassword 旧密码 */
  oldPassword: string;
  /** newPassword 新密码 */
  newPassword: string;
};
