資料科學與經濟分析入門：期末專案 Part 3
題目：政策性調薪是否縮減了職場貧富差距？—— 2016-2026 年主管職與基層勞工薪資倍數變動分析
指導教授：朱建達 (Jian-Da Zhu) 老師
單位：輔仁大學經濟學系
組員：414351346 侯卉倢

資料夾用途
----------
RawData/  未修改的原始資料複本與 wage_file_year_manifest.csv 來源/年份對照。
Code/     可重跑的 R 清理與圖表程式。
App/      可於瀏覽器操作的 R Shiny 互動式儀表板。
Data/     依執行日期命名的乾淨 CSV、排除紀錄與資料品質/合併稽核表。
Results/YYYY-MM-DD/  依執行日期建立的統計表與 PNG 圖表版本資料夾。
Docs/     變數說明文件及處理限制。

原始資料
--------
1. raw_wages_2015.csv 至 raw_wages_2024.csv：各年度職類與企業規模薪資資料複本。
2. raw_cpi_monthly_source.xml：主計總處 CPI 月資料原始 XML 複本；保留於清理資料中，但本題核心分析不使用通膨調整。
3. wage_file_year_manifest.csv：原下載檔名、重新命名檔名與官方年份核對依據。

重要限制
--------
原始薪資下載 CSV 不含年份欄位。本專案以各檔「總計」按月薪資對照行政院主計
總處民國 104-113 年表5官方統計表，已確認各檔對應 2015-2024 年；核對紀錄保留
於 RawData/wage_file_year_manifest.csv。
來源薪資指標為「廠商僱用...平均最低薪資」，不是全體受僱員工的實領平均薪資；
資料分類為職類與員工規模，報告解釋不應擴張為各行業的平均薪資結論。
原題期間為 2016-2026，但目前薪資原始資料只涵蓋 2015-2024；因此本次可重現
實證分析為 2016-2024，2025-2026 需待補官方薪資表後延伸。

RStudio 執行步驟
---------------
1. 將工作目錄設為本專案 Code/ 目錄。
2. 若尚未安裝套件，執行：
   install.packages(c("dplyr", "purrr", "readr", "stringr", "xml2",
                      "tidyr", "ggplot2", "scales", "shiny"))
3. 執行 00_run_all_2026-05-24.R。

互動式可視化介面
----------------
1. Windows 直接雙擊專案根目錄的 啟動儀表板.bat。
2. 或在 RStudio 專案根目錄執行：
   source("App/run_dashboard.R")
3. 儀表板提供薪資倍數 KPI、主管職/基層勞工薪資走勢、描述統計與資料說明。
4. 若尚未產生 Data/clean_data_YYYY-MM-DD.csv，App 啟動時會自動執行資料清理腳本。

預期輸出
--------
Data/annual_cpi_2015_2024.csv
Data/clean_data_YYYY-MM-DD.csv
Data/data_quality_check_YYYY-MM-DD.csv
Data/cleaning_audit_YYYY-MM-DD.csv
Data/excluded_wage_records_YYYY-MM-DD.csv
Results/YYYY-MM-DD/analysis_run_info.txt
Results/YYYY-MM-DD/raw_data_inspection_report.txt
Results/YYYY-MM-DD/policy_wage_gap_yearly.csv
Results/YYYY-MM-DD/policy_wage_gap_descriptive_stats.csv
Results/YYYY-MM-DD/policy_wage_gap_summary.csv
Results/YYYY-MM-DD/01_supervisor_grassroots_wage_trend.png
Results/YYYY-MM-DD/02_supervisor_grassroots_wage_ratio.png
Results/YYYY-MM-DD/03_policy_wage_gap_descriptive_stats.png
Reports/policy_wage_gap_report_YYYY-MM-DD.pptx



結果版本管理
------------
每次執行分析腳本時，系統會依執行當日日期自動建立或使用 Results/YYYY-MM-DD/
子資料夾。例如於 2026-05-24 執行，輸出會位於 Results/2026-05-24/；
日後重新執行會寫入當日資料夾，便於保留不同日期的分析版本。
