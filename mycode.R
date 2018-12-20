setwd("E:/projects/I and M bank")
libs <- c("dplyr", "magrittr", "ggplot2", "readr", "plotly", "tidyr", "GGally",
          "survival", "data.table")

install_or_load_pack <- function(pack){
  create.pkg <- pack[!(pack %in% installed.packages()[, "Package"])]
  if (length(create.pkg))
    install.packages(create.pkg, dependencies = TRUE)
  lapply(libs, require, character.only = T, warn.conflicts=F, quietly=T)
  #I know I should be using purr here, but this is before the Tidyverse is loaded. I know you Tidyverse trend setters will have me here.
  }
install_or_load_pack(libs)
Obituaries <- read_csv("Dataset/Obituaries_Dataset.csv")

#Replace missing values with 0 to indicate censoring

any(is.na(Obituaries$Death_to_Burial))
Obituaries$Death_to_Burial[is.na(Obituaries$Death_to_Burial)] <- -2
Obituaries$Death_to_Burial <- as.numeric(Obituaries$Death_to_Burial)
any(is.na(Obituaries$Death_to_Announce))
# Obituaries$Death_to_Announce[is.na(Obituaries$Death_to_Announce)] <- 0

# Recode selected variables into dummy variables
# 1. Gender
table(Obituaries$Gender)
Obituaries$Gender <- ifelse(Obituaries$Gender == "Male", 1, 0)
# 2. Color
typeof(Obituaries$Color)
table(Obituaries$Color)
# Convert all observations to upper case 
Obituaries$Color <- toupper(Obituaries$Color)
Obituaries$Color <- ifelse(Obituaries$Color == "YES", 1, 0)

# 3. Fund Raising
table(Obituaries$Fundraising)
Obituaries$Fundraising <- ifelse(Obituaries$Fundraising == "Yes", 1, 0)

# 4. Spouse Alive
table(Obituaries$Spouse_Alive)
Obituaries$Spouse_Alive <- ifelse(Obituaries$Spouse_Alive == "Yes", 1, 0)

# 5. Spouse Gender
table(Obituaries$Spouse_gender)
Obituaries$Spouse_gender <- ifelse(Obituaries$Spouse_gender == "Yes", 1, 0)

# Create curve of Gender and time between death and burial
# Create asurvival object
table(Obituaries$Death_to_Burial)
#Create a column indicating censoring status after filtering for abnormal cases
Obituaries1 <- dplyr::filter(Obituaries,
                             Death_to_Burial >= 0 && Death_to_Burial != -2) %>%
                dplyr::mutate(Status = case_when(.$Death_to_Burial == -2 ~ 1,
                                                 .$Death_to_Burial > 0 ~ 2))
table(Obituaries1$Status)
Obituaries1$SurvObj <- with(Obituaries1, Surv(Death_to_Burial, Status == 2))

km.by.fundraising <- survfit(SurvObj ~ Fundraising, data = Obituaries1, conf.type = "log-log")
km.by.fundraising
ggsurv(km.by.fundraising)
