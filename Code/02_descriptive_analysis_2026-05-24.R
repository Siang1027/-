# Descriptive statistics and plots for supervisor/grassroots wage gap analysis.

required_packages <- c("dplyr", "readr", "tidyr", "ggplot2", "scales")
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
library(readr)
library(tidyr)
library(ggplot2)
library(scales)

locate_project_root <- function() {
  candidates <- c(".", "..")
  valid <- candidates[dir.exists(file.path(candidates, "Data"))]
  if (length(valid) == 0) {
    stop("Run 01_data_cleaning_2026-05-24.R first, then run from the root or Code directory.")
  }
  normalizePath(valid[[1]], winslash = "/", mustWork = TRUE)
}

stat_row <- function(data, variable, label) {
  values <- data[[variable]]
  tibble(
    variable = label,
    N = sum(!is.na(values)),
    Mean = mean(values, na.rm = TRUE),
    Median = median(values, na.rm = TRUE),
    Min = min(values, na.rm = TRUE),
    Max = max(values, na.rm = TRUE),
    SD = sd(values, na.rm = TRUE)
  )
}

project_root <- locate_project_root()
data_dir <- file.path(project_root, "Data")
run_date <- format(Sys.Date(), "%Y-%m-%d")
results_dir <- file.path(project_root, "Results", run_date)
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

clean_data_files <- list.files(
  data_dir,
  pattern = "^clean_data_[0-9]{4}-[0-9]{2}-[0-9]{2}[.]csv$",
  full.names = TRUE
)
if (length(clean_data_files) == 0) {
  stop("No dated clean_data CSV exists in Data/. Run the cleaning script first.")
}
clean_data_path <- sort(clean_data_files, decreasing = TRUE)[[1]]

clean_data <- read_csv(
  clean_data_path,
  show_col_types = FALSE,
  locale = locale(encoding = "UTF-8")
)

target_start_year <- 2016L
target_end_year <- 2026L
available_end_year <- min(target_end_year, max(clean_data$year, na.rm = TRUE))
analysis_years <- target_start_year:available_end_year
supervisor_category <- "主管及監督人員"
grassroots_category <- "基層技術工及勞力工"

required_categories <- c(supervisor_category, grassroots_category)
missing_categories <- setdiff(
  required_categories,
  clean_data |> filter(record_type == "job_category") |> pull(job_category) |> unique()
)
if (length(missing_categories) > 0) {
  stop("Missing required job categories: ", paste(missing_categories, collapse = ", "))
}

wage_gap_yearly <- clean_data |>
  filter(
    record_type == "job_category",
    year %in% analysis_years,
    job_category %in% required_categories
  ) |>
  select(year, job_category, nominal_wage) |>
  mutate(group = recode(
    job_category,
    `主管及監督人員` = "主管職",
    `基層技術工及勞力工` = "基層勞工"
  )) |>
  select(year, group, nominal_wage) |>
  pivot_wider(names_from = group, values_from = nominal_wage) |>
  arrange(year) |>
  transmute(
    year,
    supervisor_wage = `主管職`,
    grassroots_wage = `基層勞工`,
    wage_gap = supervisor_wage - grassroots_wage,
    wage_ratio = supervisor_wage / grassroots_wage,
    supervisor_growth = (supervisor_wage / lag(supervisor_wage) - 1) * 100,
    grassroots_growth = (grassroots_wage / lag(grassroots_wage) - 1) * 100,
    ratio_change_pct = (wage_ratio / lag(wage_ratio) - 1) * 100
  )

if (any(is.na(wage_gap_yearly$supervisor_wage)) || any(is.na(wage_gap_yearly$grassroots_wage))) {
  stop("Supervisor or grassroots wage series contains missing values for the analysis period.")
}

wage_long <- wage_gap_yearly |>
  select(year, supervisor_wage, grassroots_wage) |>
  pivot_longer(
    cols = c(supervisor_wage, grassroots_wage),
    names_to = "group",
    values_to = "wage"
  ) |>
  mutate(group = recode(
    group,
    supervisor_wage = "主管職",
    grassroots_wage = "基層勞工"
  ))

wage_group_stats <- wage_long |>
  group_by(group) |>
  summarise(
    N = sum(!is.na(wage)),
    Mean = mean(wage, na.rm = TRUE),
    Median = median(wage, na.rm = TRUE),
    Min = min(wage, na.rm = TRUE),
    Max = max(wage, na.rm = TRUE),
    SD = sd(wage, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(variable = paste0(group, "名目月薪")) |>
  select(variable, N, Mean, Median, Min, Max, SD)

policy_gap_stats <- bind_rows(
  wage_group_stats,
  stat_row(wage_gap_yearly, "wage_gap", "主管職與基層勞工月薪差距"),
  stat_row(wage_gap_yearly, "wage_ratio", "主管職/基層勞工薪資倍數"),
  stat_row(wage_gap_yearly, "supervisor_growth", "主管職年增率(%)"),
  stat_row(wage_gap_yearly, "grassroots_growth", "基層勞工年增率(%)"),
  stat_row(wage_gap_yearly, "ratio_change_pct", "薪資倍數年變動率(%)")
) |>
  mutate(across(c(Mean, Median, Min, Max, SD), ~round(.x, 3)))

policy_wage_gap_summary <- tibble(
  item = c(
    "requested_period",
    "available_empirical_period",
    "supervisor_category",
    "grassroots_category",
    "ratio_first_year",
    "ratio_last_year",
    "ratio_change",
    "gap_first_year",
    "gap_last_year",
    "gap_change"
  ),
  value = c(
    paste0(target_start_year, "-", target_end_year),
    paste0(min(wage_gap_yearly$year), "-", max(wage_gap_yearly$year)),
    supervisor_category,
    grassroots_category,
    round(wage_gap_yearly$wage_ratio[wage_gap_yearly$year == min(wage_gap_yearly$year)], 3),
    round(wage_gap_yearly$wage_ratio[wage_gap_yearly$year == max(wage_gap_yearly$year)], 3),
    round(
      wage_gap_yearly$wage_ratio[wage_gap_yearly$year == max(wage_gap_yearly$year)] -
        wage_gap_yearly$wage_ratio[wage_gap_yearly$year == min(wage_gap_yearly$year)],
      3
    ),
    round(wage_gap_yearly$wage_gap[wage_gap_yearly$year == min(wage_gap_yearly$year)], 0),
    round(wage_gap_yearly$wage_gap[wage_gap_yearly$year == max(wage_gap_yearly$year)], 0),
    round(
      wage_gap_yearly$wage_gap[wage_gap_yearly$year == max(wage_gap_yearly$year)] -
        wage_gap_yearly$wage_gap[wage_gap_yearly$year == min(wage_gap_yearly$year)],
      0
    )
  )
)

write_csv(wage_gap_yearly, file.path(results_dir, "policy_wage_gap_yearly.csv"))
write_csv(policy_gap_stats, file.path(results_dir, "policy_wage_gap_descriptive_stats.csv"))
write_csv(policy_wage_gap_summary, file.path(results_dir, "policy_wage_gap_summary.csv"))

writeLines(
  c(
    paste("analysis_run_date:", run_date),
    paste("clean_data_source:", file.path("Data", basename(clean_data_path))),
    paste("requested_period:", paste0(target_start_year, "-", target_end_year)),
    paste("available_empirical_period:", paste0(min(wage_gap_yearly$year), "-", max(wage_gap_yearly$year))),
    "topic: 政策性調薪是否縮減了職場貧富差距？——主管職與基層勞工薪資倍數變動分析",
    "note: Current raw wage files support 2016-2024 for this comparison; 2025-2026 require additional official wage tables."
  ),
  file.path(results_dir, "analysis_run_info.txt"),
  useBytes = TRUE
)

p1 <- ggplot(wage_long, aes(x = year, y = wage, color = group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = wage_gap_yearly$year) +
  scale_y_continuous(labels = label_comma(prefix = "$")) +
  labs(
    title = "主管職與基層勞工名目月薪走勢",
    subtitle = paste0(min(wage_gap_yearly$year), "-", max(wage_gap_yearly$year), " 年；單位：新臺幣元"),
    x = "年份",
    y = "名目月薪",
    color = "職類"
  ) +
  theme_minimal(base_size = 12)

p2 <- ggplot(wage_gap_yearly, aes(x = year, y = wage_ratio)) +
  geom_line(color = "#276FBF", linewidth = 1) +
  geom_point(color = "#276FBF", size = 2.2) +
  scale_x_continuous(breaks = wage_gap_yearly$year) +
  scale_y_continuous(labels = number_format(accuracy = 0.01, suffix = " 倍")) +
  labs(
    title = "主管職／基層勞工薪資倍數變動",
    subtitle = "倍數下降代表兩組職類薪資差距縮小",
    x = "年份",
    y = "薪資倍數"
  ) +
  theme_minimal(base_size = 12)

p3 <- ggplot(policy_gap_stats, aes(x = reorder(variable, Mean), y = Mean)) +
  geom_col(fill = "#2E86AB") +
  coord_flip() +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "描述統計平均值比較",
    subtitle = "完整數值請見 policy_wage_gap_descriptive_stats.csv",
    x = NULL,
    y = "平均值"
  ) +
  theme_minimal(base_size = 12)

ggsave(file.path(results_dir, "01_supervisor_grassroots_wage_trend.png"), p1, width = 9, height = 5.8, dpi = 300)
ggsave(file.path(results_dir, "02_supervisor_grassroots_wage_ratio.png"), p2, width = 9, height = 5.8, dpi = 300)
ggsave(file.path(results_dir, "03_policy_wage_gap_descriptive_stats.png"), p3, width = 9, height = 6, dpi = 300)

message("Policy wage-gap analysis completed. Output written to: ", results_dir)
