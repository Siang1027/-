# 變數說明文件

乾淨資料輸出檔：`Data/clean_data_YYYY-MM-DD.csv`（以程式執行日期命名；本次為 `clean_data_2026-05-24.csv`）

| 變數 | 資料型態 | 意義與單位 |
| --- | --- | --- |
| `year` | Integer | 西元年份，2015-2024。 |
| `record_type` | Character | 觀察值種類：`overall`、`job_category` 或 `company_size`。 |
| `job_category` | Character | 職類名稱；僅 `record_type = job_category` 有值，名稱經跨年統合。 |
| `company_size` | Character | 企業員工規模；僅 `record_type = company_size` 有值，例如 `300人以上`、`29人以下`。 |
| `source_item` | Character | 原始表中項目名稱，保留作稽核追蹤。 |
| `nominal_wage` | Numeric | 按月計薪者每人每月平均最低薪資，新臺幣元；原始 `-` 視為缺失。 |
| `daily_wage` | Numeric | 按日計薪者每人每日平均最低薪資，新臺幣元。 |
| `hourly_wage` | Numeric | 按時計薪者每人每時平均最低薪資，新臺幣元。 |
| `source_file` | Character | 對應之未修改原始薪資 CSV 檔名。 |
| `cpi` | Numeric | CPI 總指數年平均，取自每年 12 個月原始值之平均；基期為民國 110 年 = 100。 |
| `real_wage` | Numeric | 實質月薪，計算方式為 `nominal_wage / cpi * 100`。 |
| `real_wage_growth` | Numeric | 同一職類或同一規模相較前一年度之實質薪資成長率（%）：`(當期 real_wage / 前期 real_wage - 1) * 100`。 |

薪資倍數分析輸出檔：`Results/YYYY-MM-DD/policy_wage_gap_yearly.csv`

| 變數 | 資料型態 | 意義與單位 |
| --- | --- | --- |
| `supervisor_wage` | Numeric | `主管及監督人員` 名目月薪，新臺幣元。 |
| `grassroots_wage` | Numeric | `基層技術工及勞力工` 名目月薪，新臺幣元。 |
| `wage_gap` | Numeric | 主管職與基層勞工月薪差距，新臺幣元。 |
| `wage_ratio` | Numeric | 主管職月薪除以基層勞工月薪之倍數。 |
| `supervisor_growth` | Numeric | 主管職名目月薪年增率，百分比。 |
| `grassroots_growth` | Numeric | 基層勞工名目月薪年增率，百分比。 |
| `ratio_change_pct` | Numeric | 薪資倍數相較前一年的變動率，百分比。 |

描述統計輸出檔：`Results/YYYY-MM-DD/policy_wage_gap_descriptive_stats.csv`

| 欄位 | 意義 |
| --- | --- |
| `N` | 樣本數／有效觀察數（Obs）。 |
| `Mean` | 平均數。 |
| `Median` | 中位數。 |
| `Min` | 最小值。 |
| `Max` | 最大值。 |
| `SD` | 標準差。 |

## 資料處理原則

1. `RawData` 僅存放原始檔複本與來源對照表，R 程式不覆寫其內容。
2. CPI 原始資料為 XML 月資料，清理腳本篩選「總指數」「原始值」，再計算年平均。
3. 薪資 CSV 中職類列與企業規模列共存在同一表格，使用 `record_type` 區隔後才進行成長率計算。
4. 原始薪資 CSV 沒有年份欄位；`wage_file_year_manifest.csv` 已以行政院主計總處民國 104-113 年表 5 的總計月薪逐年核對 2015-2024 對照。
5. 以月薪作為核心分析欄位；月薪缺失或非正值的列不納入乾淨資料，並另存於 `Data/excluded_wage_records_YYYY-MM-DD.csv` 供檢核。
