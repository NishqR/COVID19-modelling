# COVID19-modelling
NetLogo model of the spread of COVID-19 in a typical metropolitan city, with people who travel about their homes, shops, workplaces. 



## Running the model
In order to run the model (covidmodel.nlogo), you need to download and install NetLogo, which can be found here - https://ccl.northwestern.edu/netlogo/. Alternatively, you can download this model, upload it and run it online on NetLogo Web. 

To start the model, simply click on Setup and the Go. The parameters are tuned to maintain an R0 value similar to that of COVID-19, but you can play around with them and see how it affects the results. More information about the different parameters can be found in ODD.pdf. 
![Sample Run](/images/sample_run.gif)



#### A typical run of the model can look something like this (Day 7)

Yellow agents are infected, and in their incubation period.

Orange agents are infected, in their incubation period, and infectious.

Red agents are in their symptomatic period.

Grey agents are unexposed to the virus.

More info on the defaults chosen to model the different stages of the virus can be found in analysis_report.pdf (Under Stage 2)
![Sample Run](/images/day7.png)



#### A typical run of the model can look something like this (Day 24)

Red agents are in their symptomatic period

Green agents have recovered from the virus

![Sample Run](/images/day24.png)



## Analysis Report

In addition to the ODD, there is a full analysis report that analyses the results from different stages of implementation of the model (which can be found in the implementation by stages folder). This is allows us to analyze how well the policy intervention proposed works in terms of reducing the R0 value and keeping the economy afloat.

Here is just a quick excerpt from the report: 
![Sample Run](/images/analysisreport.jpg)
