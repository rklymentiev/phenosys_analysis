library(shiny)
library(tidyverse)
library(lubridate)
library(plotly)
library(DT)

hline <- function(y = 0, color = "red") {
  list(
    line = list(color = color, width = 0.5, dash = 'dot'),
    x0 = 0, x1 = 1, xref = "paper",
    y0 = y, y1 = y
  )
}

ui <- navbarPage("Dashboard",
                 theme = shinythemes::shinytheme("journal"),
                 tabPanel("5-CSRTT",
                          sidebarLayout(
                            sidebarPanel(
                              fileInput("file_main", "Choose Main File(s)",
                                        multiple = TRUE,
                                        accept = c(".csv")),
                              fileInput("file_iti", "Choose File(s) with ITI's Data",
                                        multiple = TRUE,
                                        accept = c(".csv")),
                              # fileInput("file_iti", "Choose CSV File with ITIs",
                              #           multiple = FALSE,
                              #           accept = c(".csv")),
                              uiOutput("date_window"),
                              # sliderInput("date_window",
                              #             "Dates:",
                              #             min = as.Date("2016-01-01","%Y-%m-%d"),
                              #             max = as.Date("2016-12-01","%Y-%m-%d"),
                              #             value = c(as.Date("2016-01-01"), as.Date("2016-02-01")),
                              #             timeFormat="%Y-%m-%d"),
                              sliderInput("acc_thresh", "Accuracy Threshold:", min = 50, max = 100, value = 80, step = 1),
                              uiOutput("trial_window"),
                              # uiOutput("min_trial_number"),
                              width = 3
                            ),
                            
                            # Main panel for displaying outputs ----
                            mainPanel(
                              tabsetPanel(type = "tabs",
                                          tabPanel(title = "Summary",
                                                   br(),
                                                   htmlOutput("summary"),
                                                   br(),
                                                   plotlyOutput('total_trials')
                                          ),
                                          tabPanel(title = "Plots by Session",
                                                   tabsetPanel(type = "pills",
                                                               tabPanel(title = "Accuracy",
                                                                        br(),
                                                                        plotlyOutput('accuracy_by_session'),
                                                                        br(),
                                                                        plotlyOutput("total_accuracy_by_session"),
                                                                        br(),
                                                                        plotlyOutput("total_accuracy_by_subj")),
                                                               tabPanel(title = "Omit Rate",
                                                                        br(),
                                                                        plotlyOutput("omit_by_session"),
                                                                        br(),
                                                                        plotlyOutput("total_omit_by_session"),
                                                                        br(),
                                                                        plotlyOutput("total_omit_by_subj")),
                                                               tabPanel(title = "Premature Response",
                                                                        br(),
                                                                        plotlyOutput('premature_by_session'),
                                                                        br(),
                                                                        plotlyOutput("total_premature_by_session"),
                                                                        br(),
                                                                        plotlyOutput("total_premature_by_subj")),
                                                               tabPanel(title = "Correct Latency",
                                                                        br(),
                                                                        plotlyOutput('corr_lat_by_session'),
                                                                        br(),
                                                                        plotlyOutput("total_corr_lat_by_session"),
                                                                        br(),
                                                                        plotlyOutput("total_corr_lat_by_subj")),
                                                               tabPanel(title = "Incorrect Latency",
                                                                        br(),
                                                                        plotlyOutput('incorr_lat_by_session'),
                                                                        br(),
                                                                        plotlyOutput("total_incorr_lat_by_session"),
                                                                        br(),
                                                                        plotlyOutput("total_incorr_lat_by_subj")),
                                                               tabPanel(title = "Reward Latency",
                                                                        br(),
                                                                        plotlyOutput('rew_lat_by_session'),
                                                                        br(),
                                                                        plotlyOutput("total_rew_lat_by_session"),
                                                                        br(),
                                                                        plotlyOutput("total_rew_lat_by_subj"))
                                                   )
                                          ),
                                          tabPanel(title = "Plots by Stimulus Duration",
                                                   tabsetPanel(type = "pills",
                                                               tabPanel(title = "Accuracy",
                                                                        br(),
                                                                        plotlyOutput("accuracy_by_stimDur"),
                                                                        br(),
                                                                        plotlyOutput("total_accuracy_by_stimDur")),
                                                               tabPanel(title = "Omit Rate",
                                                                        br(),
                                                                        plotlyOutput("omit_by_stimDur"),
                                                                        br(),
                                                                        plotlyOutput("total_omit_by_stimDur")),
                                                               tabPanel(title = "Premature Response",
                                                                        br(),
                                                                        plotlyOutput("premature_by_stimDur"),
                                                                        br(),
                                                                        plotlyOutput("total_premature_by_stimDur")),
                                                               tabPanel(title = "Correct Latency",
                                                                        br(),
                                                                        plotlyOutput("corr_lat_by_stimDur"),
                                                                        br(),
                                                                        plotlyOutput("total_corr_lat_by_stimDur")),
                                                               tabPanel(title = "Incorrect Latency",
                                                                        br(),
                                                                        plotlyOutput("incorr_lat_by_stimDur"),
                                                                        br(),
                                                                        plotlyOutput("total_incorr_lat_by_stimDur")),
                                                               tabPanel(title = "Reward Latency",
                                                                        br(),
                                                                        plotlyOutput("rew_lat_by_stimDur"),
                                                                        br(),
                                                                        ))
                                          ),
                                          tabPanel(title = "Plots by ITIs",
                                                   br(),
                                                   plotlyOutput("total_premature_by_iti")
                                                   ),
                                          tabPanel(title = "Raw Data",
                                                   tabsetPanel(type = "pills",
                                                               tabPanel(title = "Excluded Data",
                                                                        br(),
                                                                        DT::dataTableOutput('exc_data')),
                                                               tabPanel(title = "Summary by Session",
                                                                        br(),
                                                                        DT::dataTableOutput('totals_by_session')),
                                                               tabPanel(title = "Summary by Stimulus Duration",
                                                                        br(),
                                                                        DT::dataTableOutput('totals_by_stimulusDuration'))))
                                          
                              )
                            )
                          )),
                 tabPanel("2VDLR")
                 )
  
  # 
  # tabPanel("5-CSRTT"),
  
  
# Define server logic to read selected file --------
server <- function(input, output) {
  

  # data input --------------------------------------------------------------

  # load all data
  main_data <- reactive({ 
    
    req(input$file_main) ## ?req #  require that the input is available
    # df1 <- read_csv(file = input$file_main$datapath)
    df <- data.frame()
    for (i in 1:length(input$file_main[,1])){
      df_temp <- read_csv(file = input$file_main[[i, 'datapath']])
      df <- bind_rows(df, df_temp)
    }
    df$session <- as.character(df$session)
    
    return(df)
  })
  
  data_iti <- reactive({ 
    
    req(input$file_iti) ## ?req #  require that the input is available
    df <- data.frame()
    for (i in 1:length(input$file_iti[,1])){
      df_temp <- read_csv(file = input$file_iti[[i, 'datapath']])
      df <- bind_rows(df, df_temp)
    }
    df$session <- as.character(df$session)
    
    df <- df %>% 
      group_by(IdLabel, iti) %>% 
      summarise(nPremature = sum(nPremature)) %>% 
      ungroup()
    
    return(df)
  })
  
  # exclude some observations
  excluded_df <- reactive({
    
    df <- main_data() %>%
      dplyr::filter(outcome == "undefined" | rewardLatency == -1)
    
    return(df)
  })

  # filter data and add phase

  
  data <- reactive({
    
    df <- main_data() %>% 
      dplyr::filter(outcome != "undefined") %>% 
      dplyr::filter(rewardLatency != -1 | is.na(rewardLatency)) %>% 
      dplyr::filter(date(trialStart) >= input$date_window[1] & date(trialStart) <= input$date_window[2])
    
    # add phase
    df <- df %>% 
      group_by(IdLabel, session) %>% 
      mutate(sessionStart = min(trialStart)) %>% 
      mutate(phase = case_when(
        hour(sessionStart) >= 6 & hour(sessionStart) < 18 ~ "light",
        TRUE ~ "dark"))
    
    return(df)
  })
  
  output$exc_data <- renderDT(excluded_df())
  

  # window size setup -------------------------------------------------------

  output$trial_window <- renderUI({
    max_val <- data() %>%
      group_by(IdLabel, stimulusDuration) %>%
      summarise(m = max(trialByStimDuration)) %>%
      ungroup() %>%
      summarise(max(m))

    max_val <- plyr::round_any(as.integer(max_val), 50, f = ceiling)  

    sliderInput("trial_window", "Trial by Stimulus Duration Window:",
                min = 1, max = max_val, value = c(0, max_val), step = 50)
  })
  
  output$date_window <- renderUI({
    unique_dates <- unique(date(main_data()$trialStart))
    max_date <- max(unique_dates)
    min_date <- min(unique_dates)

    sliderInput("date_window", "Filter by Date:",
                min = min_date, max = max_date, value = c(min_date, max_date), step = 1)
  })
  
  # max_trial_number
  # output$min_trial_number <- renderUI({
  #   window_upper <- input$max_trial_number
  #   sliderInput(
  #     inputId = "min_trial_number", label = "Min Trial Number:",
  #     value = 1, min = 1, max = window_upper-49, step = 50)
  # })
  
  
  # summary table
  
  output$summary <- renderText({

    paste0("<b>Start Time</b>: ", min(data()$trialStart),
           "<br><b>End Time</b>: ", max(data()$trialStart) + data()$trialDuration[data()$trialStart == max(data()$trialStart)],
           "<br><b>Number of Subjects</b>: ", length(unique(data()$IdRFID)),
           "<br><b>Subject IDs</b>: ", paste(unique(data()$IdLabel), collapse = ", "))
  })



  # PLOTS -------------------------------------------------------------------

  # Total trials

  output$total_trials <- renderPlotly({
    data() %>% 
      group_by(IdLabel, stimulusDuration) %>% 
      summarize(trials_total = max(trialByStimDuration)) %>% 
      ungroup() %>% 
      mutate(stimulusDuration = as.character(stimulusDuration)) %>% 
      plot_ly(x = ~IdLabel, y = ~trials_total, color = ~stimulusDuration,
              type = "bar", text = ~stimulusDuration, opacity = 0.8,
              # marker = list(
              #   color = 'rgba(158,202,225, 0.5)',
              #               line = list(color = 'rgb(8,48,107)',
              #                           width = 1.5)),
              hovertemplate = paste('<B>IdLabel</B>: %{x}',
                                    '<br><B>Total Trials</B>: %{y}',
                                    '<br><B>Stimulus Duration</B>: %{text}')
      ) %>% 
      layout(barmode = 'stack',
             title = "<b>Total Trials by Subject</b>",
             xaxis = list(title = "<b>IdLabel</b>"),
             yaxis = list(title = "<b>Number of Trials</b>"),
             legend = list(title = list(text = '<b>Stimulus Duration</b>'))
      )
  })
  
  # TOTALS BY SESSION ------------------------------------------------
  
  totals_by_session <- reactive({ 
    df <- data() %>% 
    group_by(IdLabel, session, outcome) %>% 
    summarise(outcome_count = length(trial),
              responseLatency = round(mean(responseLatency), 3),
              rewardLatency = round(mean(rewardLatency),3)) %>% 
    ungroup() %>% 
    pivot_wider(names_from = outcome, values_from = c(outcome_count, responseLatency, rewardLatency)) %>% 
    rename(correct_latency = responseLatency_correct,
           incorrect_latency = responseLatency_incorrect,
           reward_latency = rewardLatency_correct,
           correct = outcome_count_correct,
           incorrect = outcome_count_incorrect,
           omission = outcome_count_omission) %>% 
    select (-c(responseLatency_omission, rewardLatency_incorrect, rewardLatency_omission)) %>% 
    mutate(across(c(correct, incorrect, omission), ~replace_na(.x, 0))) %>% 
    left_join(y = data() %>% 
                group_by(IdLabel, session) %>% 
                summarize(nPremature = sum(nPremature)),
              on = c("IdLabel", "session")) %>% 
    left_join(data() %>% 
                select(IdLabel, session, sessionStart, phase) %>%
                unique(),
              by = c("IdLabel", "session")) %>% 
    mutate(trial_count = correct + incorrect + omission, 
           total_count_wo_omit = correct + incorrect,
           accuracy = round(correct*100 / total_count_wo_omit, 2),
           omit_ratio = round(omission*100 / trial_count, 2),
           premature_ratio = round(nPremature*100 / (nPremature + trial_count), 2)) %>% 
    relocate(sessionStart, .after = session) %>% 
    relocate(phase, .after = sessionStart)
    
    return(df)
  })
  
  output$totals_by_session <- renderDT(totals_by_session())
  
  # Accuracy ------------------------------------------------
  
  # by session 
  output$accuracy_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(color_in = case_when(
        phase == "dark" ~ "rgb(0, 0, 0)",
        TRUE ~ "rgb(255, 255, 255)"),
        color_out = case_when(
          accuracy > input$acc_thresh ~ "rgba(0, 200, 0, 0.8)",
          TRUE ~ "rgba(200, 0, 0, 0.8)")) %>% 
      plot_ly(x = ~session, y = ~accuracy, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              text = ~phase,
              marker = list(color = ~color_in,
                            size = 10,
                            line = list(
                              color = ~color_out,
                              width = 2)
              ),
              hovertemplate = paste('<B>Session</B>: %{x}',
                                    '<br><B>Accuracy</B>: %{y:.2f}',
                                    '<br><b>Phase: </b>%{text}')) %>% 
      layout(title = "<b>Accuracy by Sessions</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Accuracy</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')),
             shapes = list(hline(input$acc_thresh)))
  })
  
  # by subject
  
  output$total_accuracy_by_subj <- renderPlotly({
    totals_by_session()  %>% 
      mutate(session = as.character(session)) %>%
      plot_ly(x = ~IdLabel, y = ~accuracy, color = ~IdLabel,
              type = "box", boxpoints = 'all', text = ~session,
              hovertemplate = paste('<B>Accuracy</B>: %{y}',
                                    '<br><B>Session</B>: %{text}')) %>% 
      layout(title = "<b>Accuracy (average from all Sessions)</b>",
             xaxis = list(title = "<b>IdLabel</b>"),
             yaxis = list(title = "<b>Accuracy</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')),
             shapes = list(hline(input$acc_thresh)))
  })
  
  # by session
  
  output$total_accuracy_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(session = as.character(session)) %>%
      plot_ly(x = ~session, y = ~accuracy, name = ' ',
              type = "box", boxpoints = 'all', text = ~IdLabel,
              marker = list(color = 'rgba(158,202,225, 0.5)',
                            line = list(color = 'rgb(8,48,107)')),
              hovertemplate = paste('<B>Accuracy</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>%
      layout(title = "<b>Accuracy (average from all Subjects)</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Accuracy</b>, [%]"),
             shapes = list(hline(input$acc_thresh)))
  })

  # Omit Rate -----------
  
  # by session
  
  output$omit_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(color_in = case_when(
        phase == "dark" ~ "rgb(0, 0, 0)",
        TRUE ~ "rgb(255, 255, 255)")) %>% 
      plot_ly(x = ~session, y = ~omit_ratio, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              text = ~phase,
              marker = list(color = ~color_in,
                            size = 10,
                            line = list(color = "black",
                                        width = 2)),
              hovertemplate = paste('<B>Session</B>: %{x}',
                                    '<br><B>Omit Rate</B>: %{y:.2f}',
                                    '<br><b>Phase: </b>%{text}')) %>% 
      layout(title = "<b>Omit Rate by Sessions</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Omit Rate</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by subject
  
  output$total_omit_by_subj <- renderPlotly({
    totals_by_session()  %>% 
      plot_ly(x = ~IdLabel, y = ~omit_ratio, color = ~IdLabel,
              type = "box", boxpoints = 'all', text = ~session,
              hovertemplate = paste('<B>Omit Rate</B>: %{y}',
                                    '<br><B>Session</B>: %{text}')) %>% 
      layout(title = "<b>Omit Rate (average from all Sessions)</b>",
             xaxis = list(title = "<b>IdLabel</b>"),
             yaxis = list(title = "<b>Omit Rate</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by session
  
  output$total_omit_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(session = as.character(session)) %>%
      plot_ly(x = ~session, y = ~omit_ratio, name = ' ',
              type = "box", boxpoints = 'all', text = ~IdLabel,
              marker = list(color = 'rgba(158,202,225, 0.5)',
                            line = list(color = 'rgb(8,48,107)')),
              hovertemplate = paste('<B>Omit Rate</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>%
      layout(title = "<b>Omit Rate (average from all Subjects)</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Omit Rate</b>, [%]"))
  })
  
  # Premature Response -----------
  
  # by session
  
  output$premature_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(color_in = case_when(
        phase == "dark" ~ "rgb(0, 0, 0)",
        TRUE ~ "rgb(255, 255, 255)")) %>% 
      plot_ly(x = ~session, y = ~premature_ratio, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              text = ~phase,
              marker = list(color = ~color_in,
                            size = 10,
                            line = list(color = "black",
                                        width = 2)),
              hovertemplate = paste('<B>Session</B>: %{x}',
                                    '<br><B>Premature Response</B>: %{y:.2f}',
                                    '<br><b>Phase: </b>%{text}')) %>% 
      layout(title = "<b>Premature Response by Sessions</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Premature Response</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by subject
  
  output$total_premature_by_subj <- renderPlotly({
    totals_by_session()  %>% 
      plot_ly(x = ~IdLabel, y = ~premature_ratio, color = ~IdLabel,
              type = "box", boxpoints = 'all', text = ~session,
              hovertemplate = paste('<B>Premature Response</B>: %{y}',
                                    '<br><B>Session</B>: %{text}')) %>% 
      layout(title = "<b>Premature Response (average from all Sessions)</b>",
             xaxis = list(title = "<b>IdLabel</b>"),
             yaxis = list(title = "<b>Premature Response</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by session
  
  output$total_premature_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(session = as.character(session)) %>%
      plot_ly(x = ~session, y = ~premature_ratio, name = ' ',
              type = "box", boxpoints = 'all', text = ~IdLabel,
              marker = list(color = 'rgba(158,202,225, 0.5)',
                            line = list(color = 'rgb(8,48,107)')),
              hovertemplate = paste('<B>Premature Response</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>%
      layout(title = "<b>Premature Response (average from all Subjects)</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Premature Response</b>, [%]"))
  })
  
  # Correct Latency -----------
  
  # by session
  
  output$corr_lat_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(color_in = case_when(
        phase == "dark" ~ "rgb(0, 0, 0)",
        TRUE ~ "rgb(255, 255, 255)")) %>% 
      plot_ly(x = ~session, y = ~correct_latency, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              text = ~phase,
              marker = list(color = ~color_in,
                            size = 10,
                            line = list(color = "black",
                                        width = 2)),
              hovertemplate = paste('<B>Session</B>: %{x}',
                                    '<br><B>Correct Latency</B>: %{y:.2f}',
                                    '<br><b>Phase: </b>%{text}')) %>% 
      layout(title = "<b>Correct Latency by Sessions</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Correct Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by subject
  
  output$total_corr_lat_by_subj <- renderPlotly({
    totals_by_session()  %>% 
      plot_ly(x = ~IdLabel, y = ~correct_latency, color = ~IdLabel,
              type = "box", boxpoints = 'all', text = ~session,
              hovertemplate = paste('<B>Correct Latency</B>: %{y}',
                                    '<br><B>Session</B>: %{text}')) %>% 
      layout(title = "<b>Correct Latency (average from all Sessions)</b>",
             xaxis = list(title = "<b>IdLabel</b>"),
             yaxis = list(title = "<b>Correct Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by session
  
  output$total_corr_lat_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(session = as.character(session)) %>%
      plot_ly(x = ~session, y = ~correct_latency, name = ' ',
              type = "box", boxpoints = 'all', text = ~IdLabel,
              marker = list(color = 'rgba(158,202,225, 0.5)',
                            line = list(color = 'rgb(8,48,107)')),
              hovertemplate = paste('<B>Correct Latency</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>%
      layout(title = "<b>Correct Latency (average from all Subjects)</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Correct Latency</b>, [s]"))
  })

  # Incorrect Latency -----------
  
  # by session
  
  output$incorr_lat_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(color_in = case_when(
        phase == "dark" ~ "rgb(0, 0, 0)",
        TRUE ~ "rgb(255, 255, 255)")) %>% 
      plot_ly(x = ~session, y = ~incorrect_latency, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              text = ~phase,
              marker = list(color = ~color_in,
                            size = 10,
                            line = list(color = "black",
                                        width = 2)),
              hovertemplate = paste('<B>Session</B>: %{x}',
                                    '<br><B>Incorrect Latency</B>: %{y:.2f}',
                                    '<br><b>Phase: </b>%{text}')) %>% 
      layout(title = "<b>Incorrect Latency by Sessions</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Incorrect Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by subject
  
  output$total_incorr_lat_by_subj <- renderPlotly({
    totals_by_session()  %>% 
      plot_ly(x = ~IdLabel, y = ~incorrect_latency, color = ~IdLabel,
              type = "box", boxpoints = 'all', text = ~session,
              hovertemplate = paste('<B>Incorrect Latency</B>: %{y}',
                                    '<br><B>Session</B>: %{text}')) %>% 
      layout(title = "<b>Incorrect Latency (average from all Sessions)</b>",
             xaxis = list(title = "<b>IdLabel</b>"),
             yaxis = list(title = "<b>Incorrect Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by session
  
  output$total_incorr_lat_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(session = as.character(session)) %>%
      plot_ly(x = ~session, y = ~incorrect_latency, name = ' ',
              type = "box", boxpoints = 'all', text = ~IdLabel,
              marker = list(color = 'rgba(158,202,225, 0.5)',
                            line = list(color = 'rgb(8,48,107)')),
              hovertemplate = paste('<B>Incorrect Latency</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>%
      layout(title = "<b>Incorrect Latency (average from all Subjects)</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Incorrect Latency</b>, [s]"))
  })
  
  # Reward Latency -----------
  
  # by session
  
  output$rew_lat_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(color_in = case_when(
        phase == "dark" ~ "rgb(0, 0, 0)",
        TRUE ~ "rgb(255, 255, 255)")) %>% 
      plot_ly(x = ~session, y = ~reward_latency, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              text = ~phase,
              marker = list(color = ~color_in,
                            size = 10,
                            line = list(color = "black",
                                        width = 2)),
              hovertemplate = paste('<B>Session</B>: %{x}',
                                    '<br><B>Reward Latency</B>: %{y:.2f}',
                                    '<br><b>Phase: </b>%{text}')) %>% 
      layout(title = "<b>Reward Latency by Sessions</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Reward Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by subject
  
  output$total_rew_lat_by_subj <- renderPlotly({
    totals_by_session()  %>% 
      plot_ly(x = ~IdLabel, y = ~reward_latency, color = ~IdLabel,
              type = "box", boxpoints = 'all', text = ~session,
              hovertemplate = paste('<B>Reward Latency</B>: %{y}',
                                    '<br><B>Session</B>: %{text}')) %>% 
      layout(title = "<b>Reward Latency (average from all Sessions)</b>",
             xaxis = list(title = "<b>IdLabel</b>"),
             yaxis = list(title = "<b>Reward Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
  # total by session
  
  output$total_rew_lat_by_session <- renderPlotly({
    totals_by_session() %>% 
      mutate(session = as.character(session)) %>%
      plot_ly(x = ~session, y = ~reward_latency, name = ' ',
              type = "box", boxpoints = 'all', text = ~IdLabel,
              marker = list(color = 'rgba(158,202,225, 0.5)',
                            line = list(color = 'rgb(8,48,107)')),
              hovertemplate = paste('<B>Reward Latency</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>%
      layout(title = "<b>Reward Latency (average from all Subjects)</b>",
             xaxis = list(title = "<b>Session</b>"),
             yaxis = list(title = "<b>Reward Latency</b>, [s]"))
  })
  
  
  # TOTALS BY STIMULUS DURATION ------------------------------------------------------
  
  totals_by_stimulusDuration <- reactive({

    df <- data() %>% 
      filter(between(trialByStimDuration, input$trial_window[1], input$trial_window[2])) %>% 
      group_by(IdLabel, stimulusDuration, outcome) %>% 
      summarise(outcome_count = length(trialByStimDuration), 
                responseLatency = round(mean(responseLatency), 3),
                rewardLatency = round(mean(rewardLatency),3)) %>% 
      ungroup() %>% 
      pivot_wider(names_from = outcome, values_from = c(outcome_count, responseLatency, rewardLatency)) %>% 
      rename(correct_latency = responseLatency_correct,
             incorrect_latency = responseLatency_incorrect,
             reward_latency = rewardLatency_correct,
             correct = outcome_count_correct,
             incorrect = outcome_count_incorrect,
             omission = outcome_count_omission) %>% 
      select (-c(responseLatency_omission, rewardLatency_incorrect, rewardLatency_omission)) %>%
      mutate(across(everything(), ~replace_na(.x, 0))) %>% 
      left_join(y = data() %>% 
                  filter(between(trialByStimDuration, input$trial_window[1], input$trial_window[2])) %>% 
                  group_by(IdLabel, stimulusDuration) %>% 
                  summarize(nPremature = sum(nPremature)),
                on = c("IdLabel", "stimulusDuration")) %>% 
      mutate(trial_count = correct + incorrect + omission, 
             total_count_wo_omit = correct + incorrect,
             accuracy = round(correct*100 / total_count_wo_omit, 2),
             omit_ratio = round(omission*100 / trial_count, 2),
             premature_ratio = round(nPremature*100 / (nPremature + trial_count), 2)) 

    return(df)
  })
  
  output$totals_by_stimulusDuration <- renderDT(totals_by_stimulusDuration())
  

  # Accuracy ------------------------
  
  # by stimulusDuration
  
  output$accuracy_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      mutate(msize = trial_count/(input$trial_window[2] - input$trial_window[1]) * 15,
             color_out = case_when(
               accuracy > input$acc_thresh ~ "rgba(0, 200, 0, 0.8)",
               TRUE ~ "rgba(200, 0, 0, 0.8)")) %>% 
      plot_ly(x = ~stimulusDuration, y = ~accuracy, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              marker = list(size = ~msize,
                            line = list(
                              color = ~color_out,
                              width = 2)
              ),
              hovertemplate = paste('<B>Stimulus Duration</B>: %{x}',
                                    '<br><B>Accuracy</B>: %{y:.2f}')) %>% 
      layout(title = "<b>Accuracy by Stimulus Duration</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Accuracy</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')),
             shapes = list(hline(input$acc_thresh)))  
  })
  
  # Total
  
  output$total_accuracy_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      plot_ly(x = ~stimulusDuration, y = ~accuracy, name = ' ', 
              type = "box", boxpoints = 'all', text = ~IdLabel,
              hovertemplate = paste('<B>Accuracy</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>% 
      layout(title = "<b>Accuracy (average from all Subjects)</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Accuracy</b>, [%]"),
             shapes = list(hline(input$acc_thresh)))
  })
  
  # Omit Rate -------------------------------------------------
  
  output$omit_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      mutate(msize = trial_count/(input$trial_window[2] - input$trial_window[1]) * 15) %>% 
      plot_ly(x = ~stimulusDuration, y = ~omit_ratio, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              marker = list(size = ~msize),
              hovertemplate = paste('<B>Stimulus Duration</B>: %{x}',
                                    '<br><B>Omit Rate</B>: %{y:.2f}')) %>% 
      layout(title = "<b>Omit Rate by Stimulus Duration</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Omit Rate</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))  
  })
  
  # Total
  
  output$total_omit_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      plot_ly(x = ~stimulusDuration, y = ~omit_ratio, name = ' ', 
              type = "box", boxpoints = 'all', text = ~IdLabel,
              hovertemplate = paste('<B>Omit Rate</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>% 
      layout(title = "<b>Omit Rate (average from all Subjects)</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Omit Rate</b>, [%]"))
  })
  
  # Premature Response ----------
  
  output$premature_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      mutate(msize = trial_count/(input$trial_window[2] - input$trial_window[1]) * 15) %>% 
      plot_ly(x = ~stimulusDuration, y = ~premature_ratio, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              marker = list(size = ~msize),
              hovertemplate = paste('<B>Stimulus Duration</B>: %{x}',
                                    '<br><B>Premature Response</B>: %{y:.2f}')) %>% 
      layout(title = "<b>Premature Response by Stimulus Duration</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Premature Response</b>, [%]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))  
  })
  
  # Total
  
  output$total_premature_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      plot_ly(x = ~stimulusDuration, y = ~premature_ratio, name = ' ', 
              type = "box", boxpoints = 'all', text = ~IdLabel,
              hovertemplate = paste('<B>Premature Response</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>% 
      layout(title = "<b>Premature Response (average from all Subjects)</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Premature Response</b>, [%]"))
  })
  
  # Correct Latency-----
  output$corr_lat_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      mutate(msize = trial_count/(input$trial_window[2] - input$trial_window[1]) * 15) %>% 
      plot_ly(x = ~stimulusDuration, y = ~correct_latency, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              marker = list(size = ~msize),
              hovertemplate = paste('<B>Stimulus Duration</B>: %{x}',
                                    '<br><B>Correct Latency</B>: %{y:.2f}')) %>% 
      layout(title = "<b>Correct Latency by Stimulus Duration</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Correct Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))  
  })
  
  # Total
  
  output$total_corr_lat_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      plot_ly(x = ~stimulusDuration, y = ~correct_latency, name = ' ', 
              type = "box", boxpoints = 'all', text = ~IdLabel,
              hovertemplate = paste('<B>Correct Latency</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>% 
      layout(title = "<b>Correct Latency (average from all Subjects)</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Correct Latency</b>, [s]"))
  })
  
  # Incorrect Latency-----
  output$incorr_lat_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      mutate(msize = trial_count/(input$trial_window[2] - input$trial_window[1]) * 15) %>% 
      plot_ly(x = ~stimulusDuration, y = ~incorrect_latency, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              marker = list(size = ~msize),
              hovertemplate = paste('<B>Stimulus Duration</B>: %{x}',
                                    '<br><B>Incorrect Latency</B>: %{y:.2f}')) %>% 
      layout(title = "<b>Incorrect Latency by Stimulus Duration</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Incorrect Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))  
  })
  
  # Total
  
  output$total_incorr_lat_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      plot_ly(x = ~stimulusDuration, y = ~incorrect_latency, name = ' ', 
              type = "box", boxpoints = 'all', text = ~IdLabel,
              hovertemplate = paste('<B>Incorrect Latency</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>% 
      layout(title = "<b>Incorrect Latency (average from all Subjects)</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Incorrect Latency</b>, [s]"))
  })
  
  # Reward Latency-----
  output$rew_lat_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      mutate(msize = trial_count/(input$trial_window[2] - input$trial_window[1]) * 15) %>% 
      plot_ly(x = ~stimulusDuration, y = ~reward_latency, color = ~IdLabel,
              type = 'scatter', mode = 'lines+markers', 
              marker = list(size = ~msize),
              hovertemplate = paste('<B>Stimulus Duration</B>: %{x}',
                                    '<br><B>Reward Latency</B>: %{y:.2f}')) %>% 
      layout(title = "<b>Reward Latency by Stimulus Duration</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Reward Latency</b>, [s]"),
             legend = list(title = list(text = '<b>IdLabel</b>')))  
  })
  
  # Total
  
  output$total_rew_lat_by_stimDur <- renderPlotly({
    totals_by_stimulusDuration() %>% 
      plot_ly(x = ~stimulusDuration, y = ~reward_latency, name = ' ', 
              type = "box", boxpoints = 'all', text = ~IdLabel,
              hovertemplate = paste('<B>Reward Latency</B>: %{y}',
                                    '<br><B>IdLabel</B>: %{text}')) %>% 
      layout(title = "<b>Reward Latency (average from all Subjects)</b>",
             xaxis = list(title = "<b>Stimulus Duration</b>, [ms]"),
             yaxis = list(title = "<b>Reward Latency</b>, [s]"))
  })
  
  # Totals by ITI --------------
  
  output$total_premature_by_iti <- renderPlotly({
    data_iti() %>% 
    # mutate(msize = trial_count/(input$max_trial_number - input$min_trial_number) * 15) %>% 
    plot_ly(x = ~iti, y = ~nPremature, color = ~IdLabel,
            type = 'scatter', mode = 'lines+markers', 
            # marker = list(size = ~msize),
            hovertemplate = paste('<B>ITI</B>: %{x}',
                                  '<br><B>Premature Response</B>: %{y}')) %>% 
    layout(title = "<b>Premature Response by Stimulus Duration</b>",
           xaxis = list(title = "<b>ITI</b>, [ms]"),
           yaxis = list(title = "<b>Premature Response</b>, [n]"),
           legend = list(title = list(text = '<b>IdLabel</b>')))
  })
  
}



shinyApp(ui, server)