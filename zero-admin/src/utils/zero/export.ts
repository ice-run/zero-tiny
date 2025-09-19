import { utils, writeFile } from "xlsx";
// import ExcelJS from "exceljs";
import { message } from "@/utils/message";
import type { PageData, PageParam } from "@/api";

export const doExport = async (
  searchFunction: Function,
  pageParam: PageParam<any>
) => {
  let page = 1;
  let size = 1000;
  let total = 0;
  pageParam.page = pageParam.page ?? page;
  pageParam.size = pageParam.size ?? size;
  let pageData: PageData<any> = {
    page: page,
    size: size,
    total: total,
    head: new Map<string, string>(),
    list: []
  };
  let finish = false;
  while (!finish) {
    await searchFunction({ param: pageParam })
      .then(({ data }) => {
        if (data) {
          pageData.page = data.page;
          pageData.size = data.size;
          pageData.total = data.total;
          pageData.head = data.head;
          pageData.list = pageData.list.concat(data.list ?? []);
          page = pageData.page;
          size = pageData.size;
          total = pageData.total;
          if (page * size >= total) {
            finish = true;
          }
        } else {
          finish = true;
        }
        page++;
        pageParam.page = page;
      })
      .catch((error: any) => {
        console.error("error", error);
        finish = true;
      });
    if (finish) {
      break;
    }
  }
  await exportExcel(pageData);
};

export const exportExcel = async (pageData: PageData<any>) => {
  const map: Map<string, string> = pageData.head;
  const list: Array<object> = pageData.list;
  const data: Array<string[]> = [];
  const keys: string[] = Object.keys(map);
  const head: string[] = Object.values(map);
  data.push(head);
  list.forEach(item => {
    const row: string[] = [];
    keys.forEach((_, key) => {
      row.push(Object.values(item)[key]);
    });
    data.push(row);
  });
  const workSheet = utils.aoa_to_sheet(data);
  const workBook = utils.book_new();
  utils.book_append_sheet(workBook, workSheet, "数据报表");
  writeFile(workBook, "export.xlsx");
  // const workbook = new ExcelJS.Workbook();
  // const worksheet = workbook.addWorksheet("Sheet1");
  // worksheet.addRows(data);
  // await workbook.xlsx.writeFile("export.xlsx");
  message("导出成功", {
    type: "success"
  });
};
