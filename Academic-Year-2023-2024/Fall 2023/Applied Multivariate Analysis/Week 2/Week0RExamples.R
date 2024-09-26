# ST 557: AppliedMultivariate Analysis
# Week 0 R Example Script File

# First, note that any text following the '#' symbol is
# treated as a comment, and is ignored by R when you run your code.

# It is good coding practice to include comments in your code to
# make clear to other readers and your future self what your
# code is doing, and to help keep track of which step of an
# analysis each part of your code represents.

# It is also a good idea to set a working directory to tell R 
# where to find any data you ask R to read in, and where to store 
# any files you create (plots, data, etc.).
#
# There are several ways to set a working directory, as indicated 
# in the 'RStudioIntro.pptx' document.  Here I use the 'setwd()'
# function, but you could also use the point-and-click options
# in R studio.  If you also use the 'setwd()' function, you will need
# to modify the directory path appropriately to indicate the folder
# where you are storing 

# Set working directory ±

setwd('/Users/scemerson/Documents/Old Computer Documents/ST 557 2023/Datasets')

# Read in 'AutoMpgData.csv' dataset 

autoMpg <- read.csv('AutoMpgData.csv')


# Question 1: 
# -----------
# Dimensions

dim(autoMpg)

# Question 2:
# -----------
# Head and tail of dataset

head(autoMpg)
tail(autoMpg)

# Question 3:
# -----------
# Summary of the columns in a data frame

summary(autoMpg)

# Question 4:
# -----------
# Structure of a dataset (tells variable types and levels)

str(autoMpg)

# We can also get the list of variable names using the 'names()' function:

names(autoMpg)

# Question 5:
# -----------
# Convert 'ModelYear' variable to factor or ordered factor variable

# First we could convert to an unordered factor: Note that I am going 
# to save the original values in a separate object so that we can 
# restore the original values if desired.

# One way we can select particular variables/columns in a data frame
# is to use the '$' symbol followed by the variable name:

modelYear.orig <- autoMpg$ModelYear

autoMpg$ModelYear <- factor(autoMpg$ModelYear)

# Check the effect of this command:

str(autoMpg)

# We could instead convert to an ordered factor: We designate the 
# levels and ordering of the factor variable by sorting the unique 
# values of the original 'ModelYear' variable using the 'sort()' and 
# 'unique()' functions.

autoMpg$ModelYear <- factor(modelYear.orig, levels=sort(unique(modelYear.orig)), ordered=T)

str(autoMpg)
is.ordered(autoMpg$ModelYear)

# Now I am going to revert 'ModelYear' to its original format, so that 
# the numerical summaries later make sense.  Converting to a factor was
# primarily done as an example here, but I think it makes sense to 
# continue treating year as a quantitative variable.

autoMpg$ModelYear <- modelYear.orig

str(autoMpg)

# Question 6:
# -----------
# One of the simplest ways to produce a histogram for each
# of a collection of variables is to use a 'for-loop'.  This is a 
# way to get R to iterate a process a number of times.  We will see
# more 'for-loops' throughout the course.

# First we need to tell R that we want multiple plots to appear in one 
# window.  One way to do this is to use the 'par()' function.  Then we 
# can specify that we want the plots to be in a grid filled in by row
# first (using the 'mfrow' argument) or filled in by column first (using
# the 'mfcol' argument).  Here I want the histograms to be filled in 
# across the rows, so I use 'mfrow'. I have to tell R how many rows and 
# columns of plots I want: in this case, I want 2 rows and 4 columns, so
# I say 'mfrow=c(2, 4)'.

par(mfrow=c(2,4))

# The square bracket notation [ ] is used to select elements, rows, or 
# columns from a vector/matrix/array/data frame in R. For a matrix/data 
# frame, you can provide 2 values or sets of values, separated by a comma, 
# inside the square brackets: the first value/set of values before the 
# comma indicate which row(s) you want to select, and the second value/set 
# of values after the comma indicate which column(s) you want to select.
#  
# Here are some examples:

# First three rows of 'autoMpg'.
# The colon ':' is a quick way of making a sequence of integers.

autoMpg[1:3,] 

# First 10 rows, columns 3 through 6 of 'autoMpg'.

autoMpg[1:10, 3:6]

# All rows, 7th column of 'autoMpg'.
# Leaving the row (or column) position blank means 'all the rows'
# (or columns)

autoMpg[ , 7]

# Now for the 'for-loop' to create the histogram.
# 'for(j in 1:7)' means let the variable 'j' take on each of the values
# 1, 2, ..., 7 in turn.

# hist() is the function that produces histograms. Look at the help file
# by typing the command 'help(hist)' to see some of the additional options
# for histograms.

# Here in the jth iteration I want to plot the jth column of the 'autoMpg'
# data frame.  

# I want the x-label on each histogram to be the name of the variable
# that is being plotted.  Therefore, I use 'xlab = names(autoMpg)[j]' 
# to say that the x-label for histogram j should be the jth variable name. 
# Also, R typically fills in a title for the histograms, but in this case
# I don't like the default title, so I'm telling R to leave the main title
# blank with the 'main=""' argument.

for(j in 1:7){
	hist(autoMpg[,j], xlab=names(autoMpg)[j], main="")
}

# Question 7
# -----------
# The 'pairs()' function can be used to produce pairwise scatter plots
# for all pairwise combinations of variables (columns) in a dataset.
# The plot in row j, column k of the resulting grid plots variable j on
# the y-axis vs. variable k on the x-axis.
# To color the points, we can use the 'col= ' argument, with a numeric 
# vector as its value (each element on the vector tells us the color 
# of the corresponding point).  

pairs(autoMpg[,1:7], col=autoMpg$ModelYear)

# Note that I do not include the 8th column because it is just the car 
# make/model names.

# If I want to color the points based on a custom color scale, we
# have to create a color scale (see help(rainbow) for documentation
# on some of the color palettes available in R).

pairs(autoMpg[,1:7], col=rainbow(13)[factor(autoMpg$ModelYear)])



# Question 8
# ----------
# There are several ways to compute the sample mean vector. First note
# that we have actually already seen the sample means in the output
# from the 'summary()' function. But to compute the sample mean vector
# directly, we could use a for-loop, like we did for the histograms, or 
# we could use the 'apply()' function.  I'll use both approaches here:

# First, the for-loop approach:

# We first create an empty vector that will hold the sample means that 
# we compute. The 'rep()' function repeats its first argument (0 here)
# the number of times specified by the second argument (7 here). So we
# get a vector consisting of 7 zeroes.

autoMpg.sampMeans <- rep(0, 7)

# Next, we run through the for loop, computing the mean of each variable 
# in turn using the 'mean()' function.  Again we are leaving out variable 
# 8 which is the car make/model name.

for(j in 1:7){
	autoMpg.sampMeans[j] <- mean(autoMpg[,j])
}

# Now we can examine the resulting sample mean vector:

autoMpg.sampMeans

# Next, the 'apply()' function approach: The 'apply()' function
# is used to apply the same function to each row or each column 
# of a matrix/array/data frame.  The function takes several arguments;
# the first of which is the matrix/array/data frame that we want to
# work with.  The second argument is which dimension we want to 
# apply the function to.  In this case, we want to apply the 'mean()'
# function to the columns of our data frame, so the dimension is 2 (it
# would be 1 if we wanted to apply the function to the rows). The final
# argument is the function we want to apply, in this case 'mean'.

autoMpg.sampMeans2 <- apply(autoMpg[,1:7], 2, mean)

autoMpg.sampMeans2

# Confirm that we have indeed gotten the same result with both approaches.

# Note that we get 'NA' results for 'MPG' and 'Horsepower'.  This is 
# because those variables have some missing values.  We can force R
# to compute the means using only the non-missing values by including
# the argument 'na.rm=T' (meaning 'remove the NA values'):

autoMpg.sampMeans3 <- apply(autoMpg[,1:7], 2, mean, na.rm=T)

autoMpg.sampMeans3

# Question 9
# ----------
# The sample covariance matrix (pair-wise covariances between the 
# columns/variables in our data frame) can be obtained using the 'cov()'
# function. We only want the covariances for the first seven columns
# (variables) since the eighth variable is a factor variable.  The argument
# 'use= ' tells R how to handle any observations with missing values. 
# Explore the 'help' file for 'cov()' by typing 'help(cov)' to see 
# more about the different options for handling missing values.

autoMpg.sampCov <- cov(autoMpg[,1:7], use='pairwise.complete.obs')

autoMpg.sampCov

# You could instead just compute the result without saving it as an object:

cov(autoMpg[,1:7], use='pairwise.complete.obs')

# We can also control how many digits are displayed/stored in the output using the
# 'round()' function. The second argument tells how many digits we want
# after the decimal.

round(autoMpg.sampCov, 3)

# Question 10
# -----------
# The sample correlation matrix (pair-wise correlations between the 
# columns/variables in our data frame) can be obtained using the 'cor()'
# function:

autoMpg.sampCor <- cor(autoMpg[,1:7], use='pairwise.complete.obs')

autoMpg.sampCor

# Questions 11 - 14
# -----------------
# There are several ways we could create a modified dataset, but the 
# steps we take here are:
# 1) Copy the original dataset with a new name
# 2) Replace the variable/column that we want to modify with the 
#    modified values
# Here we are going to multiply 'Displacement' (the third column) by 3.

autoMpg.mod1 <- autoMpg

autoMpg.mod1$Displacement <- autoMpg.mod1$Displacement * 3

# When we multiply a column by a number, R multiplies every element
# by that number.

# Let's compare the original dataset to the modified dataset:

head(autoMpg)
head(autoMpg.mod1)

# Question 11
# -----------

apply(autoMpg.mod1[,1:7], 2, mean, na.rm=T)

# Question 12
# -----------

cov(autoMpg.mod1[,1:7], use='pairwise.complete.obs')

# Question 13
# -----------

cor(autoMpg.mod1[,1:7], use='pairwise.complete.obs')

# Questions 15 - 18
# -----------------
# For this second modification, I'm going to modify the 'Horsepower' 
# variable by subtracting its sample mean from every observation.

autoMpg.mod2 <- autoMpg
autoMpg.mod2$Horsepower <- autoMpg.mod2$Horsepower - mean(autoMpg.mod2$Horsepower, na.rm=T)

head(autoMpg)
head(autoMpg.mod2)

# Question 15
# -----------

apply(autoMpg.mod2[,1:7], 2, mean, na.rm=T)

round(apply(autoMpg.mod2[,1:7], 2, mean, na.rm=T), 4)

# Question 16
# -----------

cov(autoMpg.mod2[,1:7], use='pairwise.complete.obs')

# Question 17
# -----------

cor(autoMpg.mod2[,1:7], use='pairwise.complete.obs')


