interface FormItemProps {
  id?: string;
  /** 用于判断是`新增`还是`修改` */
  title: string;
  username: string;
  password: string;
  nickname: string;
  valid: boolean;
}
interface FormProps {
  formInline: FormItemProps;
}

export type { FormItemProps, FormProps };
