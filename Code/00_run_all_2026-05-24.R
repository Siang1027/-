# Run the full project workflow from the project root or Code directory.
locate_code_dir <- function() {
  candidates <- c("Code", ".")
  valid <- candidates[file.exists(file.path(candidates, "01_data_cleaning_2026-05-24.R"))]
  if (length(valid) == 0) {
    stop("Run this script from the project root or the Code directory.")
  }
  normalizePath(valid[[1]], winslash = "/", mustWork = TRUE)
}

code_dir <- locate_code_dir()
source(file.path(code_dir, "01_data_cleaning_2026-05-24.R"), encoding = "UTF-8", chdir = TRUE)
source(file.path(code_dir, "02_descriptive_analysis_2026-05-24.R"), encoding = "UTF-8", chdir = TRUE)
