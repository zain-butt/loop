##Load libraries

library(tidyverse)
library(dplyr)
library(readxl)
library(data.table)
library(cowplot)
library("writexl")

##Create list of standardized excel files to loop over

loop_list = list() ##Output for loop will be saved in to this

my_path = "C:\\Desktop\\Folder\\" ##Only replace path here
list <- list.files(path = my_path)  

for(file in list){
  
  df <- file.info(file)%>% rownames_to_column(var="filename")  
  
  loop_list[[file]]=df
}

##Bind the loop outputs and clean up 
new = bind_rows( loop_list ) %>% 
  select(filename) %>% group_by(filename) %>% 
  mutate(filename=gsub("[~$]","",filename),                                   
         path=paste0(my_path,"\\",filename)) 


##Use the list of excels and extract data. 

loop_list2 = list() 

##Note, the excel template being looped over below has 3 columns, namely, Ticker, Price and Volume for stocks. We are extracting  data for only a handful of tickers.

for(path in new$path){
  tryCatch({df2 <- read_excel(path = path, sheet="Stocks",skip=9,col_names = TRUE,col_types="text") %>% 
    select(Ticker,Price,Volume) %>% 
    filter(Ticker=="ACC"|Ticker=="AIRC"|Ticker=="AMH"|Ticker=="AVB"|Ticker=="CPT"|Ticker=="EQR"|Ticker=="ESS"|Ticker=="INVH"|Ticker=="UDR"|Ticker=="WRE") %>% 
    mutate(name=path)
  
  loop_list2[[path]]=df2
  
  }, error=function(e){})
}

##Bind the loop outputs  
new2 = bind_rows( loop_list2 )

#Saving the data as a Rdata file, an excel, or plotting

##Save the output as an Rdata file  
saveRDS(new2,"C:\\Desktop\\mystocks.Rdata") ##Change name as applicable  

##Save the output as an Rdata file  
write_xlsx(new2,"N:\\Research Library\\Data\\jpm_cap_rates.xlsx")  

##Divide stocks in to two groups and plot; we compare single-family rentals stocks to their multi-family peers  

new3 <- new2  %>% 
  group_by(name) %>% 
  mutate(date=str_split(tolower(name),"et")[[1]][2],
         date=gsub(".xlsx","",date),
         date=gsub("march 11","3.15.2019",date),
         date=as.Date(date,format="%m.%d.%Y"))%>% 
  ungroup() %>% 
  filter(!is.na(date)) %>% select(-c(name)) %>%
  mutate(flag=ifelse(Ticker=="INVH"|Ticker=="AMH","sfr","mfr")) %>% ##The flag is simply creating a new column we can use to plot
  group_by(date,flag) %>%
  rename(ticker=Ticker,price=Price,volume=Volume) %>% 
  mutate(price= as.numeric(price),
         volume = as.numeric(volume),
         volume = ifelse(volume==0,lag(volume,1),volume),
         price_mean= mean(price,na.rm=T))

##Plot/save the updated dataset  

plot <- new3 %>% 
  ggplot(aes(x=date,color=flag))+geom_line(aes(y=price_mean))

saveRDS(new3,"C:\\Desktop\\mystocks.Rdata") ##Change name as applicable  
write_xlsx(new3,"N:\\Research Library\\Data\\jpm_cap_rates.xlsx")  
