# Launch the Shiny dashboard from the App directory or project root.
required_packages <- c("shiny")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop("Please install required packages before launching: ", paste(missing_packages, collapse = ", "))
}

app_dir <- if (file.exists(file.path("App", "app.R"))) "App" else "."
shiny::runApp(app_dir, host = "127.0.0.1", port = 3838, launch.browser = interactive())
