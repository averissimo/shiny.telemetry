library(shiny)
library(semantic.dashboard)
library(shiny.semantic)
library(shiny.telemetry)
library(dplyr)
library(config)

counter_ui <- function(id, label = "Counter") {
  ns <- NS(id)
  div(
    h2(class = "ui header primary", "Widgets tab content", style = "margin: 2rem"),
    box(
      title = label,
      action_button(ns("button"), "Click me!", class = "red"),
      verbatimTextOutput(ns("out")),
      width = 4, color = "teal"
    )
  )
}

ui <- dashboardPage(
  dashboardHeader(title = "Basic dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem(tabName = "dashboard", text = "Home", icon = icon("home")),
      menuItem(tabName = "widgets", text = "Another Tab", icon = icon("heart")),
      menuItem(tabName = "another-widgets", text = "Yet Another Tab", icon = icon("heart")),
      id = "uisidebar"
    )
  ),
  dashboardBody(
    use_telemetry(),
    tabItems(
      # First tab content
      tabItem(
        tabName = "dashboard",
        box(
          title = "Controls",
          sliderInput("bins", "Number of observations:", 1, 50, 30),
          action_button("apply_slider", "Apply", class = "green"),
          width = 4, color = "teal"
        ),
        box(
          title = "Old Faithful Geyser Histogram",
          plotOutput("plot1", height = 400),
          width = 11, color = "blue"
        ),
        segment(
          class = "basic",
          h3("Sample application instrumented by Shiny.telemetry"),
          p(glue::glue("Note: using MariaDB as data backend.")),
          p("Information logged:"),
          tags$ul(
            tags$li("Start of session"),
            tags$li("Every time slider changes"),
            tags$li("Click of 'Apply' button"),
            tags$li("Tab navigation when clicking on the links in the left sidebar")
          )
        )
      ),

      # Second tab content
      tabItem(
        tabName = "widgets",
        counter_ui("widgets", "Counter 1")
      ),

      # Third tab content
      tabItem(
        tabName = "another-widgets",
        counter_ui("another-widgets", "Counter 2")
      )
    )
  )
)

# Default Telemetry with data storage backend using MariaDB
telemetry <- Telemetry$new(
  app_name = "demo",
  data_storage = DataStorageMariaDB$new(
    user = "mariadb", password = "mysecretpassword"
  )
)

# Define the server logic for a module
counter_server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      count <- reactiveVal(0)
      observeEvent(input$button, {
        count(count() + 1)
      })
      output$out <- renderText(count())
      count
    }
  )
}

shinyApp(ui = ui, server = function(input, output, session) {
  telemetry$start_session(
    track_values = TRUE,
    navigation_input_id = "uisidebar"
  )

  # server code
  output$plot1 <- renderPlot({
    input$apply_slider
    x <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = isolate(input$bins) + 1)
    hist(x, breaks = bins, col = "#0099F9", border = "white")
  })

  counter_server("widgets")
  counter_server("another-widgets")
})

# shiny::shinyAppFile(system.file("examples", "mariadb", "mariadb_app.R", package = "shiny.telemetry")) # nolint: commented_code, line_length.
