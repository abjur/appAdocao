library(magrittr)
library(shiny)
library(shinycssloaders)
library(ggplot2)

# Data -------------------------------------------------------------------------
criancas <- readr::read_rds("data/criancas.rds")
n_criancas <- nrow(criancas)

pais <- readr::read_rds("data/pais.rds") %>%
  dplyr::slice_sample(n = 10)
n_pais <- nrow(pais)

tempos_entre_chegadas <- "data/tempos_entre_chegadas.rds" %>%
  readr::read_rds() %>%
  sort()

#-------------------------------------------------------------------------------
# Minhas escolhas
escolhas_sexo <-  c("Feminino" = "F", "Masculino" = "M")
escolhas_raca <-  c(
  "Amarela" = "Amarela",
  "Branca" = "Branca",
  "Negra" = "Preta",
  "Parda" = "Parda",
  "Indígena" = "Indigena"
)

# ui ---------------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("Selecione o perfil da criança Desejada"),
  fluidRow(
    column(
      width = 3,
      wellPanel(
        h4("Selecione o perfil desejado"),
        sliderInput(
          inputId = "idade",
          label = "Faixa etária",
          0,
          18,
          value = c(1, 7)
        ),
        # selecionar sexo
        checkboxGroupInput("sexo", "Sexo", escolhas_sexo, selected = escolhas_sexo),
        # selecionar raça
        checkboxGroupInput("cor", "Raça:", escolhas_raca, selected = escolhas_raca),
        actionButton("action", label = "Iniciar"),
      )
    ),
    column(
      width = 9,
      wellPanel(
        span(
          "Tempo médio de espera na fila para adotar uma criança com esse perfil (em dias):",
          tableOutput("t_adocao_m") %>% withSpinner()
        ),
        plotOutput("plot2")
      )
    )
  )
)


# Server -----------------------------------------------------------------------
server <- function(input, output, session) {

  perfil_pai <- reactive({
    data.frame(
      idade_minima = input$idade[1],
      idade_maxima = input$idade[2],
      sexo_feminino = "F" %in% input$sexo,
      sexo_masculino = "M" %in% input$sexo,
      cor_branca = "Branca" %in% input$cor,
      cor_preta = "Preta" %in% input$cor,
      cor_amarela = "Amarela" %in% input$cor,
      cor_parda = "Parda" %in% input$cor,
      cor_indigena = "Indígena" %in% input$cor
    )
  })

  tempos_adocao <- eventReactive(input$action, {
    tempo_adocao_m(
      perfil_pai(),
      criancas,
      pais,
      tempos_entre_chegadas,
      n_sim = 100
    )
  })

  output$t_adocao_m <- renderTable({
    tempos <- tempos_adocao()
    shiny::validate(shiny::need(
      all(is.finite(tempos)),
      "Tempo estimado foi maior do que 20 anos.\nPor favor, mude o perfil selecionado."
    ))

    tibble::tibble(
      media = mean(tempos),
      "1º quartil" = quantile(tempos, .25),
      mediana = median(tempos),
      "3º quartil" = quantile(tempos, .75)
    )
  })

  output$plot2 <- renderPlot({
    tempos <- tempos_adocao()
    shiny::validate(shiny::need(all(is.finite(tempos)), ""))

    ggplot(tibble::tibble(tempos = tempos), aes(x = tempos)) +
      geom_histogram(colour = "transparent", fill = "#414487", bins = 30) +
      labs(x = "Tempos de adoção") +
      theme_minimal(12)
  })

}
# Run the aplication
shinyApp(ui = ui, server = server)
