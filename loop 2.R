##Load libraries
library(tidyverse)
library(bea.R)

##Input your API key: https://apps.bea.gov/API/docs/index.htm
beaKey <- "########-####-####-####-############"

##See datasets available
beaSets(beaKey = beaKey)

beaParams(beaKey = beaKey, "Regional")

head(beaSearch("income", beaKey = beaKey))

##Check which variables/parameters are available

# Retrieve linecodes as dataframe
linecode <- beaParamVals(beaKey = beaKey, "Regional", "LineCode")$ParamValue

# Inspect the dataset
glimpse(linecode)

# The table names are available in the first parts of the "Desc" column
# Filter using str_detect() and identify the linecodes
linecode %>% filter(str_detect(Desc, "CAINC4"))


##Loop for historical data
years = c(2019,2018,2017,2016,2015,2014,2013,2012,2011,2010,
          2009,2008,2007,2006,2005,2004,2003,2002,2001,2000,
          1999,1998,1997,1996,1995,1994,1993,1992,1991,1990,
          1989,1988,1987,1986,1985,1984,1983,1982,1981,1980)

loop_list = list()
#loop_list_n = list() 

for(year in years){
  beaSpecs1 <- list(
  "UserID" = beaKey, # Set up API key
  "Method" = "GetData", # Method
  "datasetname" = "Regional", # Specify dataset
  "TableName" = "CAINC4", # Specify table within the dataset
  "LineCode" = 7010, # Specify the line code
  "GeoFips" = "MSA", # Specify the geographical level
  "Year" = year # Specify the year
)

bea_1 <- beaGet(beaSpecs1, asWide = FALSE)  

bea_totalemp <- bea_1 %>% 
  #filter(str_detect(GeoFips, "^48")) %>% 
  select(GeoFips, TimePeriod, DataValue, GeoName) %>% 
  mutate(GeoName = gsub(",.*$", "", GeoName)) %>% 
  rename(total_emp = DataValue,
         msa = GeoName)

loop_list[[year]]=bea_totalemp

}

new = bind_rows( loop_list )  

##Replace the LineCode and rerun the loop to pull in other variables and join; add loop_list_n as appropriate 

new2 = bind_rows( loop_list_2 )  
new3 = bind_rows( loop_list_3 )  


df <- new %>% 
  select(-c(Code)) %>% 
  relocate(income,.after=msa) %>% 
  left_join(new2,by = c("GeoFips", "TimePeriod", "msa")) %>% 
  left_join(new3,by = c("GeoFips", "TimePeriod", "msa"))
  
