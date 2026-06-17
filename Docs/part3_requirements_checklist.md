# Part 3 簡報要求符合性檢查表

依據：`Final_project_part3.pdf`（Step 5 至 Step 8 與 Weeks 9-11 Check-list）

## 檢查結論

| 簡報要求 | 狀態 | 專案證據 |
| --- | --- | --- |
| 建立清楚的資料夾結構，至少含 `RawData`、`Data`、`Code` | 已完成 | 專案根目錄已有 `RawData/`、`Data/`、`Code/`、`Results/`、`Docs/`、`App/`。 |
| 原始資料不可手動修改或被覆寫 | 已完成 | 原始檔複本僅存於 `RawData/`；R 腳本只讀取原始檔並將輸出寫至 `Data/`/`Results/`。先前雜湊比對已確認薪資複本與原下載檔一致。 |
| 以有意義且含日期的程式檔名管理清理工作 | 已完成 | `Code/01_data_cleaning_2026-05-24.R`、`Code/02_descriptive_analysis_2026-05-24.R`。 |
| 說明程式輸入與輸出，且流程可重現 | 已完成 | `readme.txt` 列出資料來源、執行方式與輸出；`Code/00_run_all_2026-05-24.R` 可一鍵重跑。 |
| 清理前認識資料：`str()`、`head()`/`tail()`、`summary()`、`colnames()`、`nrow()`/`ncol()` | 已完成 | `Results/YYYY-MM-DD/raw_data_inspection_report.txt` 為程式實際產出的檢視報告。 |
| 處理缺失值與不合理值，不使用 Excel 手改 | 已完成 | `-` 與空值以 R 讀為 `NA`；月薪缺失或非正值列由程式排除，另存 `Data/excluded_wage_records_YYYY-MM-DD.csv`。本次兩列為一列空白分隔列及 `2024` 年 `街頭服務工` 月薪缺失。 |
| 確認及轉換欄位資料型態 | 已完成 | 清理腳本將薪資轉為 numeric、年份轉為 integer，並標準化職類與企業規模文字。 |
| 若使用兩份資料，須先對齊細度並以 key 合併 | 已完成 | 月 CPI 以 `group_by(year)`/`summarise()` 彙整成年平均後，再以 `left_join(..., by = "year")` 合併薪資資料。 |
| 合併後確認 key 型態與列數正確 | 已完成 | `Data/cleaning_audit_YYYY-MM-DD.csv`：合併前後均為 `1,356` 列；CPI 有 `10` 個年度鍵且每年 `12` 個月；合併後 CPI 缺失 `0`。 |
| 輸出一份乾淨 CSV 至 `Data/`，檔名含日期 | 已完成 | 程式會依執行日期自動生成 `Data/clean_data_YYYY-MM-DD.csv`；本次為 `Data/clean_data_2026-06-17.csv`。 |
| 提供變數說明文件，包含名稱、型態、單位及衍生變數意義 | 已完成 | `Docs/metadata.md`。 |
| 結果依日期子資料夾保存以追蹤版本 | 已完成 | `Results/YYYY-MM-DD/`；本次輸出於 `Results/2026-06-17/`，並含 `analysis_run_info.txt`。 |
| 新增描述統計：N/Obs、Mean、Median、Min、Max、SD | 已完成 | `Results/2026-06-17/policy_wage_gap_descriptive_stats.csv`。 |

## 本次程式驗證摘要

| 檢核指標 | 結果 |
| --- | ---: |
| 原始薪資列數 | 1,358 |
| 排除之月薪缺失/非正值列數 | 2 |
| 合併前分析列數 | 1,356 |
| 合併後乾淨資料列數 | 1,356 |
| 年度數 | 10 |
| CPI 每年具完整 12 個月份之年度數 | 10 |
| 乾淨資料 CPI 缺失數 | 0 |
| 職類數 | 135 |
| 企業規模類別數 | 4 |

## 薪資倍數分析摘要

| 檢核指標 | 結果 |
| --- | ---: |
| 原題期間 | 2016-2026 |
| 目前可重現實證期間 | 2016-2024 |
| 主管職定義 | 主管及監督人員 |
| 基層勞工定義 | 基層技術工及勞力工 |
| 2016 年薪資倍數 | 2.246 |
| 2024 年薪資倍數 | 1.975 |
| 薪資倍數變化 | -0.271 |
| 2016 年月薪差距 | 28,156 |
| 2024 年月薪差距 | 28,140 |
| 月薪差距變化 | -16 |

## 資料來源核驗

薪資 CSV 原檔未含年份欄位；`RawData/wage_file_year_manifest.csv` 已以行政院主計總處民國 104-113 年表 5「總計」月薪逐年核對。官方年度總計依序為 `27,947`、`28,329`、`29,986`、`31,615`、`32,670`、`32,894`、`33,554`、`34,248`、`34,829`、`35,964`，與本專案十份薪資檔案一致。

官方來源：

- [104年事業人力僱用狀況調查報告統計表](https://www.stat.gov.tw/News_Content.aspx?n=3106&s=88564)
- [113年8月職位空缺報告統計表](https://www.stat.gov.tw/News_Content.aspx?n=3106&s=234397)
- [主計總處統計資料背景說明](https://www.stat.gov.tw/News_NoticeCalendar_Content.aspx?Ln=1&MetaI_D=152)
