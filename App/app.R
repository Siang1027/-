# Interactive Shiny dashboard for supervisor/grassroots wage-gap analysis.

required_packages <- c(
  "shiny", "dplyr", "readr", "tidyr", "ggplot2", "scales",
  "purrr", "stringr", "xml2"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop(
    "Please install required packages before running the dashboard: ",
    paste(missing_packages, collapse = ", ")
  )
}

library(shiny)
library(dplyr)
library(readr)
library(tidyr)
library(ggplot2)
library(scales)

locate_project_root <- function() {
  candidates <- c(".", "..")
  valid <- candidates[file.exists(file.path(candidates, "RawData", "wage_file_year_manifest.csv"))]
  if (length(valid) == 0) {
    stop("Run this Shiny application from the App directory or project root.")
  }
  normalizePath(valid[[1]], winslash = "/", mustWork = TRUE)
}

currency_text <- function(x) paste0("$", comma(round(x, 0)))
number_text <- function(x) number(x, accuracy = 0.01)
percent_text <- function(x) paste0(number(x, accuracy = 0.1), "%")

project_root <- locate_project_root()
data_dir <- file.path(project_root, "Data")
clean_data_files <- list.files(
  data_dir,
  pattern = "^clean_data_[0-9]{4}-[0-9]{2}-[0-9]{2}[.]csv$",
  full.names = TRUE
)

if (length(clean_data_files) == 0) {
  source(
    file.path(project_root, "Code", "01_data_cleaning_2026-05-24.R"),
    encoding = "UTF-8",
    chdir = TRUE
  )
  clean_data_files <- list.files(
    data_dir,
    pattern = "^clean_data_[0-9]{4}-[0-9]{2}-[0-9]{2}[.]csv$",
    full.names = TRUE
  )
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

wage_gap_yearly <- clean_data |>
  filter(
    record_type == "job_category",
    year %in% analysis_years,
    job_category %in% c(supervisor_category, grassroots_category)
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

wage_long <- wage_gap_yearly |>
  select(year, supervisor_wage, grassroots_wage) |>
  pivot_longer(c(supervisor_wage, grassroots_wage), names_to = "group", values_to = "wage") |>
  mutate(group = recode(group, supervisor_wage = "主管職", grassroots_wage = "基層勞工"))

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

desc_stats <- bind_rows(
  wage_group_stats,
  stat_row(wage_gap_yearly, "wage_gap", "主管職與基層勞工月薪差距"),
  stat_row(wage_gap_yearly, "wage_ratio", "主管職/基層勞工薪資倍數"),
  stat_row(wage_gap_yearly, "supervisor_growth", "主管職年增率(%)"),
  stat_row(wage_gap_yearly, "grassroots_growth", "基層勞工年增率(%)"),
  stat_row(wage_gap_yearly, "ratio_change_pct", "薪資倍數年變動率(%)")
) |>
  mutate(across(c(Mean, Median, Min, Max, SD), ~round(.x, 3)))

card <- function(title, output_id) {
  wellPanel(
    style = "min-height:110px; text-align:center;",
    tags$div(style = "font-size:14px; color:#555;", title),
    tags$div(style = "font-size:28px; font-weight:600; padding-top:12px;", textOutput(output_id))
  )
}

ui <- navbarPage(
  title = "主管職與基層勞工薪資倍數儀表板",
  header = tags$head(tags$style(HTML(".navbar-brand { font-weight: 600; } .plot-note { color:#555; margin:8px 0 16px; }"))),
  tabPanel(
    "總覽",
    fluidPage(
      h3("政策性調薪是否縮減了職場貧富差距？"),
      tags$p(
        class = "plot-note",
        "分析主管職與基層勞工的名目月薪倍數。原題設定 2016-2026；目前薪資原始檔可支援 2016-2024，2025-2026 待補官方資料。"
      ),
      fluidRow(
        column(4, card("起始年薪資倍數", "ratio_first")),
        column(4, card("最新年薪資倍數", "ratio_last")),
        column(4, card("倍數變化", "ratio_change"))
      ),
      plotOutput("ratio_plot", height = "430px")
    )
  ),
  tabPanel(
    "薪資走勢",
    fluidPage(
      h3("主管職與基層勞工名目月薪走勢"),
      plotOutput("wage_plot", height = "460px"),
      tableOutput("yearly_table")
    )
  ),
  tabPanel(
    "描述統計",
    fluidPage(
      h3("描述統計表"),
      tags$p("欄位包含樣本數 N/Obs、平均數 Mean、中位數 Median、最小值 Min、最大值 Max、標準差 SD。"),
      tableOutput("stats_table"),
      downloadButton("download_stats", "下載描述統計 CSV")
    )
  ),
  tabPanel(
    "資料說明",
    fluidPage(
      h3("分析口徑與限制"),
      tags$ul(
        tags$li("本題不以通膨或 CPI 調整後實質薪資為核心，而是使用名目月薪計算主管職/基層勞工薪資倍數。"),
        tags$li("主管職定義為原始職類 `主管及監督人員`。"),
        tags$li("基層勞工定義為原始職類 `基層技術工及勞力工`。"),
        tags$li("薪資來源為廠商僱用按月計薪者每人每月平均最低薪資，較接近僱用門檻薪資，不是全體員工實領平均薪資。"),
        tags$li("原題期間為 2016-2026；目前專案原始薪資資料只到 2024 年，2025-2026 需待補官方表格。")
      ),
      h4("核心公式"),
      tags$p(tags$code("wage_ratio = supervisor_wage / grassroots_wage")),
      tags$p(tags$code("wage_gap = supervisor_wage - grassroots_wage"))
    )
  )
)

server <- function(input, output, session) {
  first_year <- min(wage_gap_yearly$year)
  last_year <- max(wage_gap_yearly$year)

  output$ratio_first <- renderText({
    paste0(number_text(wage_gap_yearly$wage_ratio[wage_gap_yearly$year == first_year]), " 倍")
  })

  output$ratio_last <- renderText({
    paste0(number_text(wage_gap_yearly$wage_ratio[wage_gap_yearly$year == last_year]), " 倍")
  })

  output$ratio_change <- renderText({
    change <- wage_gap_yearly$wage_ratio[wage_gap_yearly$year == last_year] -
      wage_gap_yearly$wage_ratio[wage_gap_yearly$year == first_year]
    paste0(number(change, accuracy = 0.01), " 倍")
  })

  output$ratio_plot <- renderPlot({
    ggplot(wage_gap_yearly, aes(year, wage_ratio)) +
      geom_line(color = "#276FBF", linewidth = 1) +
      geom_point(color = "#276FBF", size = 2.2) +
      scale_x_continuous(breaks = wage_gap_yearly$year) +
      scale_y_continuous(labels = number_format(accuracy = 0.01, suffix = " 倍")) +
      labs(x = "年份", y = "主管職/基層勞工薪資倍數") +
      theme_minimal(base_size = 13)
  })

  output$wage_plot <- renderPlot({
    ggplot(wage_long, aes(year, wage, color = group)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      scale_x_continuous(breaks = wage_gap_yearly$year) +
      scale_y_continuous(labels = label_comma(prefix = "$")) +
      labs(x = "年份", y = "名目月薪（新臺幣元）", color = "職類") +
      theme_minimal(base_size = 13)
  })

  output$yearly_table <- renderTable({
    wage_gap_yearly |>
      transmute(
        年份 = year,
        主管職月薪 = currency_text(supervisor_wage),
        基層勞工月薪 = currency_text(grassroots_wage),
        月薪差距 = currency_text(wage_gap),
        薪資倍數 = paste0(number_text(wage_ratio), " 倍"),
        主管職年增率 = if_else(is.na(supervisor_growth), "-", percent_text(supervisor_growth)),
        基層年增率 = if_else(is.na(grassroots_growth), "-", percent_text(grassroots_growth))
      )
  }, striped = TRUE, hover = TRUE)

  output$stats_table <- renderTable({
    desc_stats |>
      mutate(across(c(Mean, Median, Min, Max, SD), ~number(.x, accuracy = 0.001)))
  }, striped = TRUE, hover = TRUE)

  output$download_stats <- downloadHandler(
    filename = function() "policy_wage_gap_descriptive_stats.csv",
    content = function(file) write_csv(desc_stats, file)
  )
}

shinyApp(ui = ui, server = server)
