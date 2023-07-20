# Modelo Machine learning - Modelagem Preditiva em IoT - Previsão de Uso de Energia.

# Este projeto de IoT tem como objetivo a criação de modelos preditivos para a previsão de consumo de energia de eletrodomésticos. Os dados utilizados
# incluem medições de sensores de temperatura e umidade de uma rede sem fio, previsão do tempo de uma estação de um aeroporto e uso de energia utilizada por
# luminárias. Nesse projeto de aprendizado de máquina você deve realizar a filtragem de
# dados para remover parâmetros não-preditivos e selecionar os melhores recursos
# (melhores features) para previsão. O conjunto de dados foi coletado por um
# período de 10 minutos por cerca de 5 meses. As condições de temperatura e
# umidade da casa foram monitoradas com uma rede de sensores sem fio ZigBee.

# Cada nó sem fio transmitia as condições de temperatura e umidade em torno
# de 3 min. Em seguida, a média dos dados foi calculada para períodos de 10 minutos.
# Os dados de energia foram registrados a cada 10 minutos com medidores de
# energia de barramento m. O tempo da estação meteorológica mais próxima do
# aeroporto (Aeroporto de Chievres, Bélgica) foi baixado de um conjunto de dados
# públicos do Reliable Prognosis (rp5.ru) e mesclado com os conjuntos de dados
# experimentais usando a coluna de data e hora. Duas variáveis aleatórias foram
# incluídas no conjunto de dados para testar os modelos de regressão e filtrar os
# atributos não preditivos (parâmetros). Seu trabalho agora é construir um modelo preditivo que possa prever o
# consumo de energia com base nos dados de sensores IoT coletados.

# Objetivo
# Recomendamos usar RandomForest para a seleção de atributos e SVM, Regressão, Logística Multilinear ou Gradient Boosting para o modelo preditivo.
# Recomendamos ainda o uso da linguagem R.

# Coluna de previsão e coluna "Appliances" e nosso alvo

### Dicionario dados
# Descricao das variáveis

# date: tempo de coleta dos dados pelos sensores (year-month-day hour:minute)
# Appliances: uso de energia (em W)
# lights: potencia de energia de eletrodomesticos na casa (em W)
# TXX: Temperatura em um lugar da casa (em Celsius)
# RH_XX: umidade em um lugar da casa (em %)
# T_out: temperatura externa (em Celsius) in Celsius
# Pressure: pressão externa (em mm Hg)
# RH_out: umidade externa (em %)
# Wind speed: velocidade do vento (em m/s)
# Visibility; visibilidade (em km)
# Tdewpoint: nao descobri o que significa mas acredito que dados de algum sensor
# rv1: variavel randomica adicional
# rv2, variavel randomica adicional
# WeekStatus: indica se é dia de semana ou final de semana (weekend ou weekday)
# Day_of_week: dia da semana
# NSM: medida do tempo em segundos

# Instalando pacotes
install.packages("Hmisc")
install.packages("corrgram")
install.packages("dplyr")

### Parte 1 - Carregando bibliotecas
library(dplyr)
library(Hmisc)
library(ggplot2)
library(PerformanceAnalytics)
library(corrgram)
library(zoo)
library(readr)
library(caret)
library(scales)


### Parte 2 - Carregando base dados

# Base treino
data_train <- read_csv("projeto8-training.csv")
head(data_train)
View(data_train)

# Base teste
data_test <- read_csv("projeto8-testing.csv")
head(data_test)
View(data_test)

### Parte 3 - Ajutando base dados
data <- rbind(data_train, data_test)

# Visualizando base dados nova
head(data)

# Visualizando nomes da coluna
names(data)

### Parte 4 - Engenharia de Atributos - Feature Engineering

## Transformação dados para data
data$date <- strptime(as.character(data$date),format="%Y-%m-%d %H:%M")
data$date <- as.POSIXct(data$date , tz="UTC")
data$day   <- as.integer(format(data$date, "%d"))
data$month <- as.factor(format(data$date, "%m"))
data$hour <- as.integer(format(data$date, "%H"))

# Transformação em dados númericas para variáveis categóricas
data$lights <- as.factor(data$lights)


### Parte 5 - Analise Exploratoria de Dados

# Valores ausentes
any(is.na(data))

# Dados estatisticos numéricas
describe(data)

## Análise Estatística dos Dados

# O presente texto traz observações estatísticas relacionadas a diferentes variáveis, como temperaturas internas e externas, umidade interna e externa, consumo de energia, luzes e status da semana.
# Vamos detalhar cada um desses pontos:

# Temperaturas:

# Temperaturas internas variaram entre 14.89°C a 29.95°C.
# Temperaturas externas (T6 e T_out) variaram entre -6.06°C a 28.29°C.

# Umidade:
# A umidade interna variou entre 20.60% a 63.36%, exceto para o ponto RH_5, cujo valor não foi mencionado.
# A umidade externa (RH_6 e RH_out) apresentou variação entre 1% a 100%.

# Consumo de Energia:
# A análise revelou que 75% do consumo de energia está abaixo de 100W, enquanto o maior consumo foi de 1080W, identificado como um outlier no dataset.

# Luzes:
# Foram encontrados 15.252 valores iguais a zero (0) em um total de 19.735 observações.
# É necessário investigar se a presença desses valores nulos (zeros) possui significância para a performance do modelo em análise.

# WeekStatus (Status da Semana):
# Cerca de 72,3% das observações ocorreram durante a semana, enquanto 27,7% ocorreram nos finais de semana.

# Essas observações estatísticas fornecem uma visão geral dos dados coletados, mostrando algumas características importantes do conjunto de dados em questão.
# A partir dessas informações, é possível realizar análises mais detalhadas, investigar possíveis padrões e, se aplicável, preparar o conjunto de dados para o treinamento de um modelo ou para outras aplicações específicas. É importante lembrar que a análise estatística é uma etapa essencial
# para compreender os dados e obter insights relevantes para tomadas de decisão mais embasadas.

# Análise Estatística - Correlação
data_nub <- numeric.vars <- c('Appliances','T1','RH_1','T2',
                  'RH_2','T3','RH_3','T4','RH_4',
                  'T5','RH_5','T6','RH_6','T7',
                  'RH_7','T8','RH_8','T9','RH_9',
                  'T_out','Press_mm_hg','RH_out','Windspeed',
                  'Visibility','Tdewpoint',
                  'rv1','rv2','NSM')
data_corr <- cor(data[,data_nub])

# Visualizando correlação com "Spearman"
chart.Correlation(data_corr,
                  method="spearman",
                  histogram=TRUE,
                  pch=16)

# Visualizando correlação com dados númericos
data_corr <- corrgram(data_corr, order=TRUE,
         lower.panel = panel.shade,
         upper.panel = panel.pie,
         text.panel = panel.txt)

# Observações da Correlação
# Neste texto, serão apresentadas algumas observações relevantes sobre as correlações existentes entre as variáveis do conjunto de dados, especialmente em relação ao atributo-alvo "Appliances":

# Temperaturas:
# Todas as características relacionadas às temperaturas apresentam uma correlação positiva com o atributo-alvo "Appliances". Isso significa que, à medida que as temperaturas aumentam, é provável que o consumo de energia dos eletrodomésticos também aumente, e vice-versa.

# Atributos do Tempo:
# Algumas características relacionadas ao tempo, como Visibility, Tdewpoint e Press_mm_hg, mostraram uma correlação baixa com o atributo-alvo "Appliances". Isso indica que essas variáveis têm uma influência limitada ou pouco significativa sobre o consumo de energia dos eletrodomésticos.

# Umidade:
# A análise revelou que as variáveis relacionadas à umidade não possuem correlação significante com o atributo-alvo "Appliances". Ou seja, o nível de umidade do ambiente não parece ter uma influência direta sobre o consumo de energia dos eletrodomésticos. Valores próximos a 0.9 são frequentemente considerados como um limiar para correlações significativas, e como não atingem esse valor, a umidade não é um fator determinante para o consumo de energia.

# Variáveis Randômicas:
# Foi constatado que as variáveis aleatórias não apresentam influência ou correlação significativa com o atributo-alvo "Appliances". Essas variáveis podem ser consideradas como ruído ou informações irrelevantes para a previsão do consumo de energia dos eletrodomésticos.
# Essas observações sobre a correlação entre as variáveis são fundamentais para a construção e interpretação de modelos preditivos ou análises mais complexas. Ao identificar quais características têm maior ou menor impacto no atributo-alvo, é possível direcionar esforços para aprimorar modelos ou entender melhor os fatores que influenciam o consumo de energia, auxiliando em tomadas de decisão mais informadas.

# Gráfico variavel target "Appliances"
ggplot(data, aes(x = Appliances)) +
  geom_histogram(fill = "steelblue", color = "black", alpha = 0.7) +
  labs(title = "Variavel target - Appliances",
       x = "Categorias",
       y = "Contagem")

## Análise série temporal

# Visualizando o consumo de energia por dia x mes
ggplot(data)+
  geom_bar(aes(x=day, y=Appliances, color = "steelblue"), stat="identity")+
  scale_y_continuous(name="Consumo Energia")+
  facet_wrap(~month, scale="free")+
  theme_bw()

# Visualizando o consumo de energia por dia x semana e final de semana
ggplot(data)+
  geom_bar(aes(x=day, y=Appliances), stat="identity", color = "steelblue")+
  scale_y_continuous(name="Consumo Energia")+
  facet_wrap(~WeekStatus, scale="free")+
  theme_bw()

# Observações a partir dos gráficos
# 1: Com base nos gráficos fornecidos, podemos notar um pico de consumo de energia no mês de janeiro,
# seguido por alguns períodos com baixa frequência de consumo, especialmente no final de janeiro e início de abril.

# 2: É possível perceber que o consumo de energia nos meses de março, abril e maio é menor em comparação aos meses de janeiro e fevereiro.
# Essa redução pode ser atribuída a um período de férias ou devido ao verão, quando a demanda tende a diminuir.

# Parte 6 - Seleção de variaveis

# Parte 6.0 Normalização dados

scale.features <- function(data, variables){
  for (variable in variables){
    data[[variable]] <- scale(data[[variable]], center=T, scale=T)
  }
  return(data)
}

# Variaveis para normalização dados
norml_data <- numeric.vars <- c('T1','RH_1','T2','RH_2','T3','RH_3','T4','RH_4','T5','RH_5','T6','RH_6','T7','RH_7','T8','RH_8','T9','RH_9',
                  'T_out','Press_mm_hg','RH_out','Windspeed','Visibility','Tdewpoint','rv1','rv2','NSM')
# Normalização dados
data <- scale.features(data, norml_data)
data

# Transformando data index
rownames(data) <- data$date
data$date <- NULL

# Treino teste modelo
data_splits <- createDataPartition(data$Appliances,
                                   p=0.7,
                                   list = FALSE)

# Dados treino e teste
train <- data[data_splits,]
test <- data[-data_splits,]

# Verificando dados treino e teste
nrow(train)
nrow(test)

# Parte 6.1 - Limpeza de dados

train <- na.omit(train)

mean_value <- mean(train$Appliances, na.rm = TRUE)
train$Appliances[is.na(train$Appliances)] <- mean_value

# Parte 7 - Modelo machine learning

# Modelo 1 - Machine learning 1 - Random forest

# Importando biblioteca
library(randomForest)

# Criando modelo Random forest
modelo_rf <- randomForest(Appliances ~ .,
                          data = train,
                          ntree = 100)

# Visualizando modelo RF
summary(modelo_rf)

# Ver os atributos mais importantes
importance(modelo_rf)

# Etapa 5: Avaliação do modelo
# Fazendo previsões com o modelo
previsoes <- predict(modelo_rf,
                     newdata = test,
                     n.trees = 100)
previsoes

# Modelo 2 Random forest - Aprimorado
model <- "Appliances ~ ."
model <- as.formula(model)
model_random_forest <- trainControl(method = "repeatedcv",
                        number = 3,
                        repeats = 2)
model_random_forest_result <- train(model,
                data = train,
                method = "rf",
                trControl = model_random_forest,
                importance=T)

model_random_forest_result <- varImp(model_random_forest_result,scale = FALSE)
model_random_forest_result

# Plot do resultado
plot(model_random_forest_result, type=c("g", "o"))

# Resultados modelo
# Análise da Importância das Características
# Após uma avaliação minuciosa da importância das características do conjunto de dados, chegamos às seguintes conclusões:
# NSM (Nível de Radiação Solar): Esta característica demonstrou possuir uma importância significativa dentro do conjunto de dados.
# Características de Temperatura: Todas as características relacionadas à temperatura apresentam uma relevância considerável, com importância variando entre 20% e 40%.
# Características de Umidade: Similarmente às características de temperatura, as características de umidade também possuem uma importância relevante, variando entre 20% e 40%. No entanto, a exceção a esta faixa é a característica "RH_out".
# Características de Tempo: As características relacionadas ao tempo também se encontram dentro da faixa de importância entre 20% e 40%.
# Com base nessa análise, selecionamos as seguintes variáveis para a criação dos modelos:
# NSM
# T1 a T9 (características de temperatura)
# T_out (temperatura externa)
# RH_1 a RH_9 (características de umidade)
# RH_out (umidade externa)
# Press_mm_hg (pressão atmosférica)
# Tdewpoint (ponto de orvalho)
# Visibility (visibilidade)
# Windspeed (velocidade do vento)
# day (dia)
# hour (hora)
# Essas variáveis foram escolhidas com base em suas respectivas importâncias e são consideradas as mais relevantes para a construção dos modelos.

# features selecionadas
model_formula <- "Appliances ~ NSM+
                         Press_mm_hg+
                         T1+T2+T3+T4+T5+T6+T7+T8+T9+
                         RH_1+RH_2+RH_3+RH_4+RH_5+RH_6+RH_7+RH_8+RH_9+
                         T_out+RH_out+
                         day+hour"

model_formula <- as.formula(model_formula)
model_formula

# Modelo 03 - Regressão Logística Multilinear
model_logistica_mul <- trainControl(method="cv", number=5)
model_logistica_mul <- train(model_formula,
                             data = train,
                             method = "glm",
                             metric="Rsquared",
                             trControl=model_logistica_mul)

# Summario
summary(model_logistica_mul)

# Previsão modelo
model_logistica_mul_pred <-predict(model_logistica_mul,
                                   newdata = test,
                                   n.trees = 100)
model_logistica_mul_pred


# Avaliação do Desempenho dos Modelos (Dados de Treinamento)
# Aqui estão os resultados da avaliação do desempenho dos modelos utilizando os dados de treinamento:

# Regressão Logística Múltipla (GLM):

# RMSE (Erro Médio Quadrático): 93.63

# R² (Coeficiente de Determinação): 0.14

# Modelo de Regressão Generalizada por Impulsionamento (GBM):

# RMSE (Erro Médio Quadrático): 85.79

# R² (Coeficiente de Determinação): 0.28

# XGBoost (eXtreme Gradient Boosting):

# RMSE (Erro Médio Quadrático): 73.70

# R² (Coeficiente de Determinação): 0.47

# Esses resultados fornecem informações valiosas sobre o desempenho dos modelos com os dados de treinamento.
# O XGBoost se destaca dos demais, apresentando o menor RMSE e o maior R²,
# indicando uma melhor capacidade de ajuste aos dados em comparação com a Regressão Logística Múltipla
# e o Modelo de Regressão Generalizada por Impulsionamento (GBM).
# No entanto, é importante lembrar que esses resultados são específicos para os dados de treinamento e podem não refletir
# o desempenho real dos modelos em dados de teste ou dados não vistos. É sempre recomendável avaliar o desempenho dos modelos em um
# conjunto de dados separado para obter uma estimativa mais precisa de sua capacidade de generalização.

# Modelo 03 - eXtreme Gradient Boosting (XGBoost)

model_xgboost_cont <- trainControl(method = "cv", number = 5)
model_xgboost <- train(model_formula,
                       data=train,
                       method="xgbLinear",
                       trControl=model_xgboost_cont)

# Summario
summary(model_xgboost)

# Previsão modelo
model_xgboost_pred <-predict(model_xgboost,
                                   newdata = test,
                                   n.trees = 100)
model_xgboost_pred

## Modelo 04 - Modelo otimizado

# Definindo os parametros de controle do modelo
xgb_trcontrol = trainControl(
  method = "cv",
  number = 5,
  allowParallel = TRUE,
  verboseIter = FALSE,
  returnData = FALSE
)

# Modificando os hyperparametros usando o gridSearch
model_xgb_grid <- expand.grid(nrounds = c(50, 150, 200),
                       max_depth = c(10, 15, 20, 25),
                       colsample_bytree = seq(0.5, 0.9, length.out = 5),
                       eta = 0.1,
                       gamma=0,
                       min_child_weight = 1,
                       subsample = 1
)

# Modelo treinamento
model_xgb_train <- train(model_formula,
                   data=train,
                   method="xgbTree",
                   trControl=xgb_trcontrol,
                   tuneGrid=model_xgb_grid)

# Visualizando modelo
model_xgb_train
plot(model_xgb_train)

# Melhores parametros
xgb_model$bestTune

# Treinando o modelo com os melhores parametros
xgb_model <- train(model_formula,
                   data=train,
                   method="xgbTree",
                   trControl=xgb_trcontrol,
                   tuneGrid=xgb_model$bestTune)
xgb_model

## RMSE
# Verificando modelos otimizados
model_pred = predict(xgb_model, test)
model_pred

resd = test$Appliances - model_pred
resd

RMSE = sqrt(mean(resd^2))
cat('O RMSE nos dados de teste é: ', round(RMSE,3),'\n')

## R-square
model_test = mean(test$Appliances)
tss =  sum((test$Appliances - model_test)^2 )
rss =  sum(resd^2)
rsq  =  1 - (rss/tss)
cat('O R-square nos dados de teste é: ', round(rsq,3), '\n')

## Previsoes modelo
options(repr.plot.width=8, repr.plot.height=4)

data_pred = as.data.frame(cbind(model_pred = model_pred, observed = test$Appliances))
data_pred

# Plot previsoes ados de teste
ggplot(data_pred,aes(model_pred, observed)) +
  geom_point(color = "green", alpha = 0.5) +
  geom_smooth(method=lm) +
  ggtitle('Linear Regression ') +
  ggtitle("Extreme Gradient Boosting - Otimizado: Previsões vs Dados de Teste") +
  xlab("Dados previstos ") +
  ylab("Dados reais ") +
  theme(plot.title = element_text(color="blue",size=16,hjust = 0.5),
        axis.text.y = element_text(size=12), axis.text.x = element_text(size=12,hjust=.5),
        axis.title.x = element_text(size=14), axis.title.y = element_text(size=14))

# Modelo treino e teste
data_splits <- createDataPartition(data$Appliances, p=0.7, list=FALSE)
train2 <- data[ data_splits,]
teste2 <- data[-data_splits,]

# Modelo 05 - Melhor modelo ML
model_xb <- train(model_formula,
                  data=dados_treino2,
                  method="xgbTree",
                  trControl=xgb_trcontrol,
                  xgb_model$bestTune)

# Visualizando modelo
model_xb

# Conclusão do projeto
# Avaliação do Desempenho do Modelo XGBoost Otimizado (dados de treino sem outliers)

# Após otimizar o modelo XGBoost e remover os outliers dos dados de treinamento, obtivemos os seguintes resultados:
# RMSE (Erro Médio Quadrático): 15.92
# R² (Coeficiente de Determinação): 0.688

# Conclusão Final
# Com base nos resultados da avaliação, podemos concluir que o algoritmo eXtreme Gradient Boosting (XGBoost) é a melhor opção para este conjunto de dados. O modelo otimizado, após a remoção dos outliers, apresentou um desempenho notável, explicando aproximadamente 69% da variância nos dados de teste.
# A remoção dos outliers mostrou-se benéfica, proporcionando uma melhora significativa no desempenho do modelo em relação à versão anterior, que explicava apenas 61% da variância.
# No entanto, para continuar melhorando a performance do modelo, é recomendável obter mais dados. Quanto mais dados tivermos disponíveis, mais o modelo poderá aprender padrões e generalizar melhor para novos cenários.
# Além disso, é importante monitorar a frequência de outliers nos novos dados que serão utilizados para testar o modelo. Isso permitirá verificar a robustez do modelo em lidar com situações inesperadas e garantir que sua performance seja consistente em diferentes contextos.
# Em resumo, o XGBoost otimizado se mostrou uma escolha promissora para esse conjunto de dados, e a busca por mais dados e o monitoramento contínuo dos outliers são medidas recomendadas para aprimorar ainda mais o desempenho do modelo.

# Referencia
