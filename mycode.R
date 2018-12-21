setwd("E:/projects/I and M bank")
libs <- c("dplyr", "magrittr", "ggplot2", "readr", "caret", "tidyr", "GGally",
          "survival", "data.table",  "plotly", "lubridate", "mice")

install_or_load_pack <- function(pack){
  create.pkg <- pack[!(pack %in% installed.packages()[, "Package"])]
  if (length(create.pkg))
    install.packages(create.pkg, dependencies = TRUE)
  lapply(libs, require, character.only = T, warn.conflicts=T, quietly=T)
  #I know I should be using purr here, but this is before the Tidyverse is loaded. I know you Tidyverse trend setters will have me here.
  }
install_or_load_pack(libs)
Obituaries <- read_csv("Dataset/Obituaries_Dataset.csv")

#############################################

#Data Cleaning
any(is.na(Obituaries$Death_to_Burial))
# Impute missing value in variable of interest with -2
Obituaries$Death_to_Burial[is.na(Obituaries$Death_to_Burial)] <- -2
Obituaries$Death_to_Burial <- as.numeric(Obituaries$Death_to_Burial)
# Obituaries$Death_to_Announce[is.na(Obituaries$Death_to_Announce)] <- 0

# Recode selected variables into dummy variables
# 1. Gender
table(Obituaries$Gender)
Obituaries$Gender <- ifelse(Obituaries$Gender == "Male", 1, 0)
# 2. Color
table(Obituaries$Color)
# Convert all observations to upper case 
Obituaries$Color <- toupper(Obituaries$Color)
Obituaries$Color <- ifelse(Obituaries$Color == "YES", 1, 0)

# 3. Fund Raising
table(Obituaries$Fundraising)
# Obituaries$Fundraising <- ifelse(Obituaries$Fundraising == "Yes", 1, 0)

# 4. Spouse Alive
table(Obituaries$Spouse_Alive)
Obituaries$Spouse_Alive <- ifelse(Obituaries$Spouse_Alive == "Yes", 1, 0)

# 5. Spouse Gender
table(Obituaries$Spouse_gender)
Obituaries$Spouse_gender <- ifelse(Obituaries$Spouse_gender == "Male", 1, 0)

# 6. Married 
Obituaries$Married <- toupper(Obituaries$Married)
table(Obituaries$Married)
Obituaries$Married <- ifelse(Obituaries$Married == "YES", 1, 0)

# 7. Burial_Week
Obituaries$Burial_Week <- toupper(Obituaries$Burial_Week)
table(Obituaries$Burial_Week)
Obituaries$Burial_Week <- ifelse(Obituaries$Burial_Week == "WEEKEND", 1, 0)

# 8. table(Obituaries3$Cause_of_Death)
Obituaries$Cause_of_Death <- toupper(Obituaries$Cause_of_Death)
table(Obituaries$Cause_of_Death)
accidents =  c("ACCIDENT", "ROAD ACCIDENT", "FIRE ACCIDENT")
illness = c("ILLNESS", "CANCER", "ILNESS", "HEART FAILURE")
Obituaries <- Obituaries %>%
  dplyr:: mutate(Cause_of_Death = ifelse(Cause_of_Death %in% accidents,
                                         1, Cause_of_Death)) %>%
  dplyr:: mutate(Cause_of_Death = ifelse(Cause_of_Death %in% illness,
                                         2, Cause_of_Death))
# 9. Burrial Day
Obituaries$Burial_Day <- toupper(Obituaries$Burial_Day)
table(Obituaries$Burial_Day)
Obituaries <- Obituaries %>%
  mutate(Burial_Day = recode_factor(Burial_Day,
                                    "MONDAY" = 1,
                                    "TUESDAY" = 2, 
                                    "WEDNESDAY" = 3,
                                    "THURSDAY" = 4,
                                    "FRIDAY" = 5, 
                                    "SATURDAY" = 6,
                                    "SUNDAY" = 7,
                                    .ordered = FALSE))

table(Obituaries$Death_to_Burial)
#Create a column indicating censoring status after filtering for abnormal cases
Obituaries1 <- dplyr::filter(Obituaries,
                             Death_to_Burial >= 0 && Death_to_Burial != -2) %>%
                dplyr::mutate(Status = case_when(.$Death_to_Burial == -2 ~ 1,
                                                 .$Death_to_Burial > 0 ~ 2))
table(Obituaries1$Status)
Obituaries$Death_to_Burial <- as.numeric(Obituaries$Death_to_Burial)
km.by.fundraising <- survfit(Surv(Death_to_Burial, Status)~ Fundraising, data = Obituaries1)
# Create curve of Gender and time between death and burial
kmplot <- ggsurv(km.by.fundraising)+
            ggtitle("Kaplan-meier survival curve of Fund raising")+
            xlab("Time in days between death and burial")+
            geom_ribbon(aes(ymin=low,ymax=up,fill=group),alpha=0.3) +
            guides(fill=FALSE) +
            coord_cartesian(xlim = c(-3, 20)) 
ggplotly(kmplot)

##########################################################
# some columns have too many missing values so we drop columns where the missing value
# is more than 40%
Obituaries3 <- as.data.frame(Obituaries[, -which(colMeans(is.na(Obituaries)) > 0.4)])

#Recode obituaries3 fundraising into dummyvariable
Obituaries3$Fundraising <- ifelse(Obituaries3$Fundraising == "Yes", 1, 0)
#check fundraising is balanced
table(Obituaries3$Fundraising) #the data set is almost balanced
#Check types of variables
str(Obituaries3)
# Drop the name variable it is not useful in prediction
Obituaries3 <- dplyr::select(Obituaries3, -c(Name))
# Convert dates to appropriate formats
Obituaries3$Announcement <- as.Date(Obituaries3$Announcement, "%m/%d/%Y")
Obituaries3$Death <- as.Date(Obituaries3$Death, "%m/%d/%Y")
Obituaries3$Burial <- as.Date(Obituaries3$Burial, "%m/%d/%Y")
# Convert numeric variables to appropriate formats
Obituaries3$No_of_Relatives <- as.numeric(Obituaries3$No_of_Relatives)
Obituaries3$Announce_to_Burial <- as.numeric(Obituaries3$Announce_to_Burial)
# Raises an Warning so we remove the variable and recalculate it.
Obituaries3 <- dplyr::select(Obituaries3, -c(Death_to_Announce)) %>%
                dplyr::mutate(Death_to_Announce = as.numeric(Announcement-Death)) %>%
                dplyr::mutate_if(is.character,as.factor)

Obituaries3$Distance_Morgue <- as.numeric(Obituaries3$Distance_Morgue)

# Recode County_Burial
table(Obituaries3$County_Burial)
Obituaries3$County_Burial <- as.character(Obituaries3$County_Burial)
Obituaries3$County_Burial <- toupper(Obituaries3$County_Burial) 
Obituaries3 <- Obituaries3%>%
                mutate(County_Burial = recode_factor(County_Burial,
                "BARINGO" = 1, "BOMET" =2, "BUNGOMA" = 3,
                "BUSIA" = 4, "ELGEYO MARAKWET" = 5,
                "EMBU" = 6, "HOMA BAY" = 7, "KAJIADO" = 8,
                "KAKAMEGA"  = 9, "KERICHO" = 10, "KIAMBU" = 11,
                "KIRINYAGA" = 12, "KISII" = 13, "KISUMU" = 14,
                "KITUI" = 15, "LAIKIPIA" = 16, "MACHAKOS" = 17,
                "MAKUENI" = 18, "MERU " = 19, "MIGORI" = 20,
                "MOMBASA" = 21,"MURANG'A" = 22, "NAIROBI" = 23,
                "NAKURU" = 24, "NANDI" = 25, "NAROK" = 26,
                "NYAMIRA" = 27, "NYANDARUA" = 28, "NYERI" = 29,
                "SIAYA" = 30, "THARAKA NITHI" = 31,
                "TRANS NZIOA" = 32, "UASIN GISHU" = 33,
                "VIHIGA " = 34,
                .ordered = FALSE))

# Recode County morgue
Obituaries3$County_Morgue <- toupper(Obituaries3$County_Morgue) 
Obituaries3 <- Obituaries3%>%
  mutate(County_Morgue = recode_factor(County_Morgue,
                                       "BARINGO" = 1, "BOMET" =2, "BUNGOMA" = 3,
                                       "BUSIA" = 4, "ELGEYO MARAKWET" = 5,
                                       "EMBU" = 6, "HOMA BAY" = 7, "KAJIADO" = 8,
                                       "KAKAMEGA"  = 9, "KERICHO" = 10, "KIAMBU" = 11,
                                       "KIRINYAGA" = 12, "KISII" = 13, "KISUMU" = 14,
                                       "KITUI" = 15, "LAIKIPIA" = 16, "MACHAKOS" = 17,
                                       "MAKUENI" = 18, "MERU " = 19, "MIGORI" = 20,
                                       "MOMBASA" = 21,"MURANG'A" = 22, "NAIROBI" = 23,
                                       "NAKURU" = 24, "NANDI" = 25, "NAROK" = 26,
                                       "NYAMIRA" = 27, "NYANDARUA" = 28, "NYERI" = 29,
                                       "SIAYA" = 30, "THARAKA NITHI" = 31,
                                       "TRANS NZIOA" = 32, "UASIN GISHU" = 33,
                                       "VIHIGA " = 34,
                                       .ordered = FALSE))

str(Obituaries3)

# Drop the Morgue column too many observations to clean on time
Obituaries3 <- dplyr::select(Obituaries3, -c(Morgue))
names(Obituaries3)


# omit missing values in date columns
Obituaries3 <- Obituaries3[!is.na(Obituaries3$Announcement),]
Obituaries3 <- Obituaries3[!is.na(Obituaries3$Death),]
Obituaries3 <- Obituaries3[!is.na(Obituaries3$Burial),]
dim(Obituaries3)

#impute missing values using package mice on non-date variables.
names(Obituaries3[4:24])
Obituaries3_impute <- mice(Obituaries3[4:24], m=5, maxit = 50, method = 'pmm', seed = 500)
#Extract imputed data from Obituaries3_impute
completedData <- complete(Obituaries3_impute,1)

# merge date columns after imputing values in other columns
Obituaries3 <-cbind.data.frame(Obituaries3[,1:3], completedData)

# Save resulting dataframe
write.csv(Obituaries3, file = "Dataset/CleanData.csv")
#############################################################
# Start model fitting
#Split data set into training and test set
CleanData <- read_csv("Dataset/CleanData.csv")
names(CleanData)
# Drop variable X1
CleanData <- dplyr::select(CleanData, -c(X1))

set.seed(113)

cutoff <- createDataPartition(CleanData$Fundraising, p = 0.75, list = FALSE)
# Separate target variable
target <- dplyr::select(CleanData, c(Fundraising))
CleanData <- dplyr::select(CleanData, -c(Fundraising))

# Remove near zero variance predictors
variances<-apply(CleanData, 2, var)
variances[which(variances<=0.0025)]
variances
# split target
str(train)
train <- CleanData[cutoff,]
test <- CleanData[-cutoff,]

# spllit target
train_target <- target[cutoff,]
test_target <- target[-cutoff,]

# Remove Multicollinearity
ncol(train)
descrCorr <- cor(train[,4:23])
highCorr <- findCorrelation(descrCorr, 0.90)
if (length(highCorr) != 0){
  train <- train[, -highCorr]
  test <- test[, -highCorr]
}

#####################################################
# Tune Model
gbmGrid <-  expand.grid(interaction.depth = 3,
                        n.trees = c(200, 198, 202),
                        shrinkage = 0.01,
                        n.minobsinnode = c(33, 35, 34))

nrow(gbmGrid)
