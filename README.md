# I and M
To begin, we asume that you already have knowledge in machine leaning using R. If that is the case clone this repository. Otherwise, consider reading the book from max kuhn [here](https://topepo.github.io/caret/index.html).

After cloning the repository open your terminal/shell and cd into the folder containing the repository.
Type the following line in the terminal
```
git checkout develop
```
This should list the following files and directory.
1. A folder called dataset
2. A file called mycode.R
3. The rest of the files are not important for now.

Using Rstudio, R GUI (The r graphical user interface), or your favorite IDE open the file called 
mycode.R.
Set the working directory to the directory containing the cloned repository by editing the first
line in the mycode.R. file i.e. edit the line `r setwd("E:/projects/I and M bank")` to reflect your current
working directory. 

## The Kaplan Meir Estimator 
Note that survival anlysis is interested in the time to event. Since our data set is only made of
dead people our time to event will be the period between death and burial. Where death marks the 
onset of the study and burial marks the event of interest.

Running the code upto line 97 produces the plot below
![alt text](https://github.com/cycks/IandM/blob/develop/Outputs/kmplot.png)

### Interpretation
From the kaplan meir curve above it is evident that funerals that call for fundraising take 
longer than those who do not before they can be burried. 

## Classifying Fundraising
I decided to develop a model that could clasify an individual's abilitty to request for fundraising
based on a set of selected features. The stochastic gradient boosting was used to select important features
before rpart was used to fit the model. The model makes the classificatio upto a 67% accuracy.

