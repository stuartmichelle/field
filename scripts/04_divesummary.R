# This is a script to determine for each dive the number of fish captured, sampled and recatpured and the same numbers at each site, also the number of dives per site.
library(tidyverse)
library(stringr)

excel_file <- ("data/GPSSurveys2017.xlsx")

# fish observation info from anem survey
fish <- readxl::read_excel(excel_file, sheet = "anemones", col_names = TRUE, na = "")
names(fish) <- str_to_lower(names(fish))
fish <- filter(fish, !is.na(id)) %>% 
  distinct()

# get dive info
site <- readxl::read_excel(excel_file, sheet = "diveinfo", col_names=TRUE)
names(site) <- stringr::str_to_lower(names(site))
site <- site %>% filter(!is.na(divenum)) %>% select(divenum, site) %>% distinct()

# fish processing info from clownfish survey
samp <- readxl::read_excel(excel_file, sheet = "clownfish", col_names = TRUE, na = "")   
names(samp) <- stringr::str_to_lower(names(samp))
samp <- filter(samp, !is.na(divenum) & gps == 4)

# make a table of observed fish
divetot <- fish %>%
  group_by(divenum) %>% 
  filter(!is.na(numfish) & spp == "APCL") %>% 
  summarise(observed = sum(numfish))

# add the site to the table
divetot <- left_join(divetot, site, by = "divenum")

# how many tissue samples were collected?  
tissue <- samp %>% 
  filter(!is.na(finid)) %>% 
  group_by(divenum) %>% 
  summarize(fins=n())
divetot <- left_join(divetot, tissue, by = "divenum")

# how many fish were captured
cap <- samp %>% filter(!is.na(size)) %>% 
    group_by(divenum) %>% 
    summarise(captured = n())
divetot <- left_join(divetot, cap, by = "divenum")

# how many fish were recaptures?
recap <- samp %>% 
  filter(recap == "Y") %>% 
  group_by(divenum) %>% 
  summarise(recap = n())

divetot <- left_join(divetot, recap, by = "divenum") 
divetot <- divetot %>% 
  select(divenum, site, observed, captured, fins, recap) %>% 
  distinct()

# are any captured more than observed?
bad <- filter(divetot, captured > observed) # the one at visca is ok because it is ????
# are there more fin clips than captured?
bad <- filter(divetot, fins > captured)
# are there ore recaps than captured?
bad <- filter(divetot, recap > captured)

# Fish per site -----------------------------------------------------------

# fish observed by site
fishobs <- left_join(fish, site, by = "divenum") %>% 
  distinct()
sitetot <- fishobs %>% 
  filter(spp == "APCL", !is.na(numfish)) %>% 
  group_by(site) %>% 
  summarise(observed = sum(numfish))

# how many tissue samples were collected?  
tissue <- left_join(samp, site, by = "divenum") %>% 
  distinct()
fins <- tissue %>% 
  filter(!is.na(finid)) %>% 
  group_by(site) %>% 
  summarise(finclip = n())

sitetot <- left_join(sitetot, fins, by = "site")

# how many fish were captured
cap <- tissue %>% 
  filter(!is.na(size)) %>% 
  group_by(site) %>% 
  summarize(captured = n())

sitetot <- left_join(sitetot, cap, by = "site")

# how many fish were recaptures?
recap <- tissue %>% 
  filter(recap == "Y") %>% 
  group_by(site) %>% 
  summarize(recap = n())

sitetot <- left_join(sitetot, recap, by = "site") 
sitetot <- sitetot %>% 
  select(site, observed, captured, finclip, recap)

# are any captured more than observed?
bad <- filter(sitetot, captured > observed) # the one at visca is ok because it is ????
# are there more fin clips than captured?
bad <- filter(sitetot, finclip > captured)
# are there ore recaps than captured?
bad <- filter(sitetot, recap > captured)

View(sitetot)
View(divetot)
