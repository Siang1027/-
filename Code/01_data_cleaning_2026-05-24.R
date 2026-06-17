# Data cleaning and construction of real-wage measures
# Project: Wages versus CPI in Taiwan, 2015-2024

required_packages <- c("dplyr", "purrr", "readr", "stringr", "xml2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop(
    "Please install required packages before running: ",
    paste(missing_packages, collapse = ", ")
  )
}

library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(xml2)

locate_project_root <- function() {
  candidates <- c(".", "..")
  valid <- candidates[file.exists(file.path(candidates, "RawData", "wage_file_year_manifest.csv"))]
  if (length(valid) == 0) {
    stop("Run this script from the project root or the Code directory.")
  }
  normalizePath(valid[[1]], winslash = "/", mustWork = TRUE)
}

project_root <- locate_project_root()
raw_dir <- file.path(project_root, "RawData")
data_dir <- file.path(project_root, "Data")
run_date <- format(Sys.Date(), "%Y-%m-%d")
results_dir <- file.path(project_root, "Results", run_date)
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

clean_label <- function(x) {
  x |>
    str_replace_all("[[:space:]　]+", "") |>
    str_trim()
}

standardize_job_category <- function(x) {
  case_when(
    x %in% c("資訊技術員", "通訊技術員", "資訊及通訊技術員") ~ "資訊及通訊技術員",
    x %in% c("技術員及助理專業人員", "技術員及助理專業人員") ~
      "技術員及助理專業人員",
    TRUE ~ x
  )
}

standardize_company_size <- function(x) {
  case_when(
    str_detect(x, "３００人.*以上|300人.*以上") ~ "300人以上",
    str_detect(x, "１００人至２９９人|100人至299人") ~ "100至299人",
    str_detect(x, "３０人至.*９９人|30人至.*99人") ~ "30至99人",
    str_detect(x, "２９人及.*以下|29人及.*以下") ~ "29人以下",
    TRUE ~ NA_character_
  )
}

manifest <- read_csv(
  file.path(raw_dir, "wage_file_year_manifest.csv"),
  show_col_types = FALSE,
  locale = locale(encoding = "UTF-8")
) |>
  select(year, raw_file)

inspection_wage_sample <- read_csv(
  file.path(raw_dir, manifest$raw_file[[1]]),
  na = c("", "-"),
  show_col_types = FALSE,
  locale = locale(encoding = "UTF-8")
)

read_wage_file <- function(year, raw_file) {
  wage <- read_csv(
    file.path(raw_dir, raw_file),
    na = c("", "-"),
    show_col_types = FALSE,
    locale = locale(encoding = "UTF-8")
  )

  if (ncol(wage) < 4) {
    stop("Wage file has fewer than four expected columns: ", raw_file)
  }

  names(wage)[1:4] <- c("source_item", "nominal_wage", "daily_wage", "hourly_wage")

  wage |>
    mutate(
      year = as.integer(year),
      source_file = raw_file,
      source_item = clean_label(source_item),
      nominal_wage = as.numeric(nominal_wage),
      daily_wage = as.numeric(daily_wage),
      hourly_wage = as.numeric(hourly_wage),
      company_size_value = standardize_company_size(source_item),
      record_type = case_when(
        is.na(source_item) | source_item == "" ~ "blank_row",
        source_item == "總計" ~ "overall",
        !is.na(company_size_value) ~ "company_size",
        source_item == "按員工規模分" ~ "section_header",
        TRUE ~ "job_category"
      ),
      job_category = if_else(
        record_type == "job_category",
        standardize_job_category(source_item),
        NA_character_
      ),
      company_size = if_else(
        record_type == "company_size",
        company_size_value,
        NA_character_
      )
    ) |>
    filter(record_type != "section_header") |>
    select(
      year, record_type, job_category, company_size, source_item,
      nominal_wage, daily_wage, hourly_wage, source_file
    )
}

wages <- pmap_dfr(manifest, read_wage_file)

cpi_xml <- read_xml(file.path(raw_dir, "raw_cpi_monthly_source.xml"), encoding = "UTF-8")
cpi_nodes <- xml_find_all(cpi_xml, ".//Obs")

cpi_annual <- tibble(
  item = xml_text(xml_find_first(cpi_nodes, "./Item")),
  time_period = xml_text(xml_find_first(cpi_nodes, "./TIME_PERIOD")),
  value_type = xml_text(xml_find_first(cpi_nodes, "./TYPE")),
  item_value = parse_number(xml_text(xml_find_first(cpi_nodes, "./Item_VALUE")))
) |>
  filter(
    item == "總指數(指數基期：民國110年=100)",
    value_type == "原始值",
    str_detect(time_period, "^20(15|16|17|18|19|20|21|22|23|24)M")
  ) |>
  mutate(year = as.integer(str_sub(time_period, 1, 4))) |>
  group_by(year) |>
  summarise(
    cpi = mean(item_value, na.rm = TRUE),
    cpi_months = sum(!is.na(item_value)),
    .groups = "drop"
  ) |>
  arrange(year)

if (any(cpi_annual$cpi_months != 12)) {
  warning("At least one CPI year does not contain exactly 12 monthly original observations.")
}

inspection_report <- capture.output({
  cat("Raw Data Inspection Report\n")
  cat("Run date:", run_date, "\n\n")
  cat("A. Wage CSV sample before cleaning:", manifest$raw_file[[1]], "\n")
  cat("colnames():\n")
  print(colnames(inspection_wage_sample))
  cat("\nnrow() / ncol():\n")
  print(c(nrow = nrow(inspection_wage_sample), ncol = ncol(inspection_wage_sample)))
  cat("\nstr():\n")
  str(inspection_wage_sample)
  cat("\nhead():\n")
  print(head(inspection_wage_sample))
  cat("\ntail():\n")
  print(tail(inspection_wage_sample))
  cat("\nsummary():\n")
  print(summary(inspection_wage_sample))
  cat("\nB. Imported wages after standardizing names/types and before filtering:\n")
  print(c(nrow = nrow(wages), ncol = ncol(wages)))
  print(summary(wages[, c("nominal_wage", "daily_wage", "hourly_wage")]))
  cat("\nC. CPI annual aggregation before joining:\n")
  print(cpi_annual)
  cat("\nEach CPI year must contain 12 monthly original-value observations.\n")
})
writeLines(inspection_report, file.path(results_dir, "raw_data_inspection_report.txt"), useBytes = TRUE)

excluded_wage_records <- wages |>
  filter(is.na(nominal_wage) | nominal_wage <= 0) |>
  mutate(
    exclusion_reason = case_when(
      is.na(nominal_wage) ~ "monthly nominal wage is missing in raw data",
      nominal_wage <= 0 ~ "monthly nominal wage is non-positive",
      TRUE ~ "unspecified"
    )
  )

analysis_wages <- wages |>
  filter(!is.na(nominal_wage), nominal_wage > 0)

clean_data <- analysis_wages |>
  left_join(cpi_annual |> select(year, cpi), by = "year") |>
  mutate(real_wage = nominal_wage / cpi * 100) |>
  group_by(record_type, job_category, company_size) |>
  arrange(year, .by_group = TRUE) |>
  mutate(
    real_wage_growth = (real_wage / lag(real_wage) - 1) * 100
  ) |>
  ungroup() |>
  arrange(record_type, job_category, company_size, year)

if (any(is.na(clean_data$cpi))) {
  stop("CPI join failed: some wage records do not have annual CPI values.")
}

if (nrow(clean_data) != nrow(analysis_wages)) {
  stop("CPI join changed the number of wage records; check year key uniqueness.")
}

if (anyDuplicated(cpi_annual$year) > 0) {
  stop("CPI annual data contains duplicated year keys.")
}

write_csv(cpi_annual, file.path(data_dir, "annual_cpi_2015_2024.csv"), na = "")
clean_data_file <- paste0("clean_data_", run_date, ".csv")
quality_file <- paste0("data_quality_check_", run_date, ".csv")
audit_file <- paste0("cleaning_audit_", run_date, ".csv")
excluded_file <- paste0("excluded_wage_records_", run_date, ".csv")
write_csv(clean_data, file.path(data_dir, clean_data_file), na = "")
write_csv(excluded_wage_records, file.path(data_dir, excluded_file), na = "")

quality_check <- clean_data |>
  summarise(
    n_records = n(),
    n_years = n_distinct(year),
    n_job_categories = n_distinct(job_category, na.rm = TRUE),
    n_company_sizes = n_distinct(company_size, na.rm = TRUE),
    missing_nominal_wage = sum(is.na(nominal_wage)),
    missing_cpi = sum(is.na(cpi)),
    missing_real_wage = sum(is.na(real_wage))
  )
write_csv(quality_check, file.path(data_dir, quality_file))

cleaning_audit <- tibble(
  audit_item = c(
    "raw_wage_rows_loaded",
    "rows_excluded_missing_or_nonpositive_nominal_wage",
    "wage_rows_before_cpi_join",
    "wage_rows_after_cpi_join",
    "cpi_year_keys",
    "cpi_years_with_12_months",
    "missing_cpi_after_join"
  ),
  value = c(
    nrow(wages),
    nrow(excluded_wage_records),
    nrow(analysis_wages),
    nrow(clean_data),
    n_distinct(cpi_annual$year),
    sum(cpi_annual$cpi_months == 12),
    sum(is.na(clean_data$cpi))
  ),
  validation = c(
    "informational",
    "review exclusion file",
    "must equal wage_rows_after_cpi_join",
    "must equal wage_rows_before_cpi_join",
    "must equal 10",
    "must equal 10",
    "must equal 0"
  )
)
write_csv(cleaning_audit, file.path(data_dir, audit_file))

message("Cleaning completed. Output written to: ", data_dir, " and ", results_dir)
