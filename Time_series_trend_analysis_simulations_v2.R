#Geret DePiper
#Simulations to test robusntess of Mann-Kendall, prewhitening, linear GLM, and GAM to assessing trends in time series
#December 14, 2017
#10, 20, 30 years
#AR(1) ARIMA(1,0,1), linear trend, quadratic trend, no trend

# Load required libraries
library(tidyr)
library(ggplot2)

# Load functions to do model selection of GLS and GAM
source("model_compare.R")

PKG <-c("Kendall",'zyp')

for (p in PKG) {
  if(!require(p,character.only = TRUE)) {
    install.packages(p)
    require(p,charcter.only=TRUE)  }
}

set.seed(436)

n <- 1000 #number of simulations
x <- 30 #number of periods

# Trend parameters are from fitting a linear model to the
# z-scored real data: 5th percentile (weak), mean (medium), 
# 95th (strong). The mean intercept of the z-scored real
# data was -0.262.
LTRENDweak   <- -0.262 + (0.004 * c(1:x)) #Linear trend
LTRENDmedium <- -0.262 + (0.051 * c(1:x)) 
LTRENDstrong <- -0.262 + (0.147 * c(1:x))
# AR values are from the real data by fitting an ar1
# model to the resids of the linear fit. The mean of
# those values was 0.433. We also include 0.8 to 
# investigate the effect of strong autocorrelation.
ARmedium <- list(ar = 0.433)
ARstrong <- list(ar = 0.8)
# Mean AR sd from the mean resids of the real data
ARsd <- 0.54^0.5
NOAR <- list()

#Adding placeholders for simulated data
LINEARweak_ARmedium <- NULL 
LINEARweak_ARstrong <- NULL 
LINEARmedium_ARmedium <- NULL 
LINEARmedium_ARstrong <- NULL
LINEARstrong_ARmedium <- NULL 
LINEARstrong_ARstrong <- NULL 

NOTREND_ARmedium <- NULL
NOTREND_ARstrong <- NULL
NOTREND_NOAR <- NULL

LINEARweak_NOAR <- NULL
LINEARmedium_NOAR <- NULL
LINEARstrong_NOAR <- NULL

NOTREND_ARmedium_RESULTS <- NULL
NOTREND_NOAR_RESULTS <- NULL
NOTREND_ARstrong_RESULTS <- NULL
LINEARweak_ARmedium_RESULTS <- NULL
LINEARweak_ARstrong_RESULTS <- NULL
LINEARmedium_ARmedium_RESULTS <- NULL
LINEARmedium_ARstrong_RESULTS <- NULL
LINEARstrong_ARmedium_RESULTS <- NULL
LINEARstrong_ARstrong_RESULTS <- NULL
LINEARweak_NOAR_RESULTS <- NULL
LINEARmedium_NOAR_RESULTS <- NULL
LINEARstrong_NOAR_RESULTS <- NULL

#initializing simulations
for (i in 1:n) {
#Generating ar(1) simulations
  for (k in c('ARmedium','ARstrong','NOAR')){
# Simulate arima process with sd set to the mean sd
# of the residuals
TEMP1 <- arima.sim(get(k), n=x, rand.gen=rnorm, sd = ARsd)
LTEMP1 <- TEMP1 + LTRENDweak
LTEMP2 <- TEMP1 + LTRENDmedium
LTEMP3 <- TEMP1 + LTRENDstrong
assign(paste0('LINEARweak_',k,sep=""),rbind(get(paste0('LINEARweak_',k,sep="")),LTEMP1))
assign(paste0('LINEARmedium_',k,sep=""),rbind(get(paste0('LINEARmedium_',k,sep="")),LTEMP2))
assign(paste0('LINEARstrong_',k,sep=""),rbind(get(paste0('LINEARstrong_',k,sep="")),LTEMP3))
assign(paste0('NOTREND_',k, sep=""),rbind(get(paste0('NOTREND_',k, sep="")), TEMP1))

for (y in c('TEMP1','LTEMP1','LTEMP2','LTEMP3')){
  # Print counter
  
  #Testing 30 year series with prewhitening Mann-Kendall technique
  TEMP_TEST1 <- zyp.trend.vector(get(y),method='yuepilon')
  TEMP_P1 <- unlist(TEMP_TEST1[6])
  TEMP_TREND1 <- unlist(TEMP_TEST1[3])
  T_1 <- cbind(TEMP_P1,TEMP_TREND1)
  #30 year standard Mann-Kendall
  TEMP_TEST12 <- MannKendall(get(y))
  T_2 <- as.double(unlist(TEMP_TEST12[2]))
  # 30-year linear model
  TEMP_lm <- fit_lm(dat = data.frame(series = get(y) %>% as.numeric,
                    time = 1:length(get(y))))
  T_lm <- TEMP_lm$best_lm$pval
  

for (j in c(10,20)) {
  #Testind 20 & 10 year series with prewhitening Mann-Kendall technique
  TEMP_TEST2 <- zyp.trend.vector(get(y)[j:x],method='yuepilon')
  TEMP_P2 <- unlist(TEMP_TEST2[6])
  TEMP_TREND2 <- unlist(TEMP_TEST2[3])
  T_1 <- cbind(T_1,TEMP_P2,TEMP_TREND2)
  #Now standard Mann_Kendall
  TEMP_TEST22 <- MannKendall(get(y)[j:x])
  TEMP_P22 <- as.double(unlist(TEMP_TEST22[2]))
  T_2 <- cbind(T_2,TEMP_P22)
  # 20-year and 10-year linear model
  TEMP_lm <- fit_lm(dat = data.frame(series = get(y)[j:x] %>% as.numeric,
                                     time = 1:length(get(y)[j:x])))
  T_lm <- cbind(T_lm, TEMP_lm$best_lm$pval)
  # 20-year and 10-year gam
  #TEMP_gam <- fit_gam(dat = data.frame(series = get(y)[j:x] %>% as.numeric,
  #                                     time = 1:length(get(y)[j:x])))
  #T_gam <- cbind(T_gam, TEMP_gam$pval)
}
  colnames(T_1) <- c('p_30_pw','Slope30_pw','p_20_pw',
                     'Slope20_pw','p_10_pw','Slope10_pw')
  colnames(T_2) <- c('p_30_mk','p_20_mk','p_10_mk')
  colnames(T_lm) <- c('p_30_gls','p_20_gls','p_10_gls')
  
if (y=='TEMP1' & k!='NOAR') {assign(paste0('NOTREND_',k,'_RESULTS',sep=""),
                                    rbind(get(paste0('NOTREND_',k,'_RESULTS',sep="")),
                                          cbind(T_1,T_2, T_lm)))
  } else if (y=='TEMP1' & k=='NOAR') {assign(paste0('NOTREND_',k,'_RESULTS',sep=""),
                                           rbind(get(paste0('NOTREND_',k,'_RESULTS',sep="")),
                                                 cbind(T_1,T_2, T_lm)))
  } else if (y=='LTEMP1') {assign(paste0('LINEARweak_',k,'_RESULTS',sep=""),
                                rbind(get(paste0('LINEARweak_',k,'_RESULTS',sep="")),
                                      cbind(T_1,T_2, T_lm)))
  } else if (y=='LTEMP2') {assign(paste0('LINEARmedium_',k,'_RESULTS',sep=""),
                                rbind(get(paste0('LINEARmedium_',k,'_RESULTS',sep="")),
                                      cbind(T_1,T_2, T_lm)))
  } else if (y=='LTEMP3') {assign(paste0('LINEARstrong_',k,'_RESULTS',sep=""),
                                rbind(get(paste0('LINEARstrong_',k,'_RESULTS',sep="")),
                                      cbind(T_1,T_2, T_lm)))}
  }
#rm(TEMP1,LTEMP1,QTEMP1)
}
}

#convert Monte Carlo simulation output (p values and slopes)
# from wide to long format for plotting
library(data.table)
results <- c("NOTREND_ARmedium_RESULTS", "NOTREND_NOAR_RESULTS", "NOTREND_ARstrong_RESULTS",
             "LINEARweak_ARmedium_RESULTS", "LINEARweak_ARstrong_RESULTS",
             "LINEARmedium_ARmedium_RESULTS","LINEARmedium_ARstrong_RESULTS",
             "LINEARstrong_ARmedium_RESULTS", "LINEARstrong_ARstrong_RESULTS",
             "LINEARweak_NOAR_RESULTS","LINEARmedium_NOAR_RESULTS","LINEARstrong_NOAR_RESULTS")


#wide to long function (Sean Lucey)
w2l <- function(x, by, by.name = 'Time', value.name = 'Value'){
  x.new <- copy(x)
  var.names <- names(x)[which(names(x) != by)]
  out <- c()
  setnames(x.new, by, 'by')
  for(i in 1:length(var.names)){
    setnames(x.new, var.names[i], 'V1')
    single.var <- x.new[, list(by, V1)]
    single.var[, Var := var.names[i]]
    out <- rbindlist(list(out, single.var))
    setnames(x.new, 'V1', var.names[i])
  }
  setnames(x.new, 'by', by)
  setnames(out, c('by', 'V1'), c(by.name, value.name))
}

#filter for p values
p_result_mat <- list()
for (i in 1:length(results)){
  z <- get(results[i])
  z <- cbind(z[,grepl("p_",colnames(get(results[i]))) == TRUE],seq(1,nrow(z),1))
  z <- data.table(z)
  z <- w2l(z, by = "V10", by.name = "replicate")
  z <- cbind(z,rep(results[i],nrow(z)))
  p_result_mat[[i]] <- z
}

# Final p dataframe
p_results <- 
  do.call(rbind, p_result_mat) %>%
  as.data.frame() %>%
  tidyr::separate(Var, 
                  c("var", "timeseries length", "method"),
                  "_") %>%
  tidyr::separate(V2, 
                  c("Trend strength", "AR strength", "Results"),
                  "_") %>%
  dplyr::mutate(`Trend strength` = substring(`Trend strength`, first = 7),
                `Trend strength` = ifelse(`Trend strength` == "D",
                                          "no",
                                          `Trend strength`),
                `Trend strength` = paste0(`Trend strength`, " trend"),
                `AR strength` = substring(`AR strength`, first = 3),
                `AR strength` = ifelse(`AR strength` == "AR",
                                          "no",
                                          `AR strength`),
                `AR strength` = paste0(`AR strength`, " AR")) %>%
  dplyr::select(-Results) %>%
  tidyr::spread(method, Value) %>%
  # remove runs that cause NAs in GLS (two runs out of 1000)
  dplyr::filter(!is.na(gls)) %>%
  tidyr::gather(method, Value, 
                -replicate, -var, 
                -`timeseries length`, -`Trend strength`,
                -`AR strength`) %>%
  dplyr::mutate(`Trend strength` = factor(`Trend strength`, 
                                          levels = c("strong trend",
                                                     "medium trend",
                                                     "weak trend",
                                                     "no trend")),
                `AR strength` = factor(`AR strength`, 
                                       levels = c("no AR",
                                                  "medium AR",
                                                  "strong AR")))
  
  

# Single scenario example
ggplot(p_results %>% 
         dplyr::filter(`Trend strength` == "strong trend",
                       `AR strength` == "no AR"), 
       aes(color = method, y = Value, 
                      x = `timeseries length`)) +
  geom_boxplot(outlier.size = 0.3, 
               outlier.alpha = 0.2) +
  ylab("p-value") +
  ggtitle("Strong Trend and No AR") +
  theme_bw() +
  theme(axis.title=element_text(size=15))

# Box and whisker plot of each scenario
ggplot(p_results, aes(color = method, y = Value, 
                      x = `timeseries length`)) +
  geom_boxplot(outlier.size = 0.3, 
               outlier.alpha = 0.2) +
  facet_grid(`Trend strength` ~ `AR strength`) +
  ylab("p-value") +
  theme_bw()

# Make table of results
p_count <- p_results
p_count$p_0.05 <- 0
p_count$p_0.05[p_count$Value<=0.05] <- 1
p_count$N_sim <- 1

p_count <- aggregate(cbind(p_0.05,N_sim)~`timeseries length`+method+`Trend strength`+`AR strength`,
                     data=p_count, FUN=sum)
p_count$p_0.05 <- p_count$p_0.05/p_count$N_sim
p_count <- p_count[which(p_count$p_0.05!=0),]
p_count <- p_count[order(p_count$`timeseries length`,p_count$`Trend strength`,p_count$`AR strength`,p_count$method),]
names(p_count) <- c("timeseries length",'method','Trend strength','AR strength','Proportion significant', 'N')
#write.csv(p_count, file="N_sim_less_05.csv")

# Create a human-readable table for each
# time series length
p_count2table_all <-
  p_count %>%
  as.data.frame() %>%
  tidyr::spread(method, `Proportion significant`)

write.csv(p_count2table_all, file="p_all.csv")

p_count2table_10 <-
  p_count %>%
  as.data.frame() %>%
  dplyr::filter(`timeseries length` == 10,
               `Trend strength` %in% c("strong trend", "no trend")) %>%
  dplyr::select(-`timeseries length`, -`N`) %>%
  tidyr::spread(method, `Proportion significant`)

write.csv(p_count2table_10, file="p_10.csv")

p_count2table_30 <-
  p_count %>%
  as.data.frame() %>%
  dplyr::filter(`timeseries length` == 30,
                `Trend strength` %in% c("strong trend", "no trend")) %>%
  dplyr::select(-`timeseries length`, -`N`) %>%
  tidyr::spread(method, `Proportion significant`)

write.csv(p_count2table_30, file="p_30.csv")
