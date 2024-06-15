import altair as alt
import pandas as pd
import json 
import os

# Create a simple dataframe from test.csv
data = json.load(open("times.json"))
dfs = {}
for key in data.keys():
   dfs[key] = pd.DataFrame(data[key])
lineCountData = json.load(open("instrCounts.json"))
istrCountDfs = {}
for key in lineCountData.keys():
   istrCountDfs[key] = pd.DataFrame(lineCountData[key])

def plot(df_name):
   df = dfs[df_name]
   df_melted = df.melt(var_name="Compilation Type", value_name="Time (s)")
   chart = alt.Chart(df_melted).mark_boxplot(extent="min-max").encode(
      alt.X('Time (s):Q', title='Time (s)', scale=alt.Scale(nice = True, zero=False)),
      alt.Y('Compilation Type:O', title='Compilation Type'),
      alt.Color('Compilation Type:O', title=None, legend=None,  # Disable the legend
         scale=alt.Scale(scheme='category10'))
   ).properties(
      width=600,  # Adjust the width
      height=200  # Adjust the height
      )

   summary_stats = df_melted.groupby('Compilation Type')['Time (s)'].agg(['mean', 'std', 'count']).reset_index()
   summary_stats.columns = ['Compilation Type', 'Average Time (s)', 'Standard Deviation (s)', 'Number of Runs']

   # table = alt.Chart(summary_stats).transform_fold(
   #     fold=['Average Time (s)', 'Standard Deviation (s)', 'Number of Runs'],
   #     as_=['Statistic', 'Value']
   # ).mark_text().encode(
   #     alt.Y('Compilation Type:O', title='Compilation Type'),
   #     alt.X('Statistic:N', title='Statistic'),
   #     alt.Text('Value:Q', format=".4e"),
   #     alt.Color('Statistic:N', legend=None)  # Use color for text differentiation
   # ).properties(
   #     width=600,  # Match the width of the chart
   #     height=100  # Adjust the height of the table
   # )

   instrDf = istrCountDfs[df_name].melt(var_name="Compilation Type", value_name="Instructions")
   # print(instrDf)

   istrCountPlot = alt.Chart(instrDf).mark_bar().encode(
      alt.X('Instructions:Q', title='Instructions', scale=alt.Scale(nice = True, zero=False)),
      alt.Y('Compilation Type:O', title='Compilation Type'),
      alt.Color('Compilation Type:O', title=None, legend=None,  # Disable the legend
         scale=alt.Scale(scheme='category10'))
   ).properties(
      width=600,  # Adjust the width
      height=200  # Adjust the height
      )

   chart.save('./media/' + df_name + '-time.svg')
   istrCountPlot.save('./media/' + df_name + '-instr.svg')
   summary_stats.to_markdown('./media/' + df_name + '-stats.md')
   # combined = alt.vconcat(
   #      chart,
   #      table,
   #      # istrCountPlot
   # ).resolve_scale(
   #         color='independent'
   #         )
   # return combined

### BenchMarkishTopics
plot("BenchMarkishTopics")
### Fibonacci
plot("Fibonacci")
### GeneralFunctAndOptimize
plot("GeneralFunctAndOptimize")
### OptimizationBenchmark
plot("OptimizationBenchmark")
### TicTac
plot("TicTac")
### array_sort
plot("array_sort")
### array_sum
plot("array_sum")
### bert
plot("bert")
### biggest
plot("biggest")
### binaryConverter
plot("binaryConverter")
### brett
plot("brett")
### creativeBenchMarkName
plot("creativeBenchMarkName")
### fact_sum
plot("fact_sum")
### hailstone
plot("hailstone")
### hanoi_benchmark
plot("hanoi_benchmark")
### killerBubbles
plot("killerBubbles")
### mile1
plot("mile1")
### mixed
plot("mixed")
### primes
plot("primes")
### programBreaker
plot("programBreaker")
### stats
plot("stats")
### wasteOfCycles
plot("wasteOfCycles")
