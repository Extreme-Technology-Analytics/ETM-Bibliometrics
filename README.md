ETM-Bibliometrics
=================

R Code for doing citation analysis on publications

<b>Instructions for Downloading and Analyzing Web of Science and Compendex data</b>

<b><i>Downloading Data:</i></b>
<ul>
  <li>Web of Science (WOS):</li>
  <ul>
    <li>Search for results under Web of Science,</li>
    <li>Click on "Save to Other File Formats" -> Select Record Content: "Full Record and Cited References", File Format: 		        "Tab-delimited (Win, UTF-8)",</li>
    <li>Click Send and save to local drive,</li>
    <li>Repeat until all article entries downloaded.</li>
  </ul>
  <li>Compendex (COM)</li>
  <ul>
    <li>Search for results under Compendex,</li>
    <li>Click Select -> Maximum (up to 500) and then click  “Save to my PC”,</li>
    <li>Select Location: “My PC”, Format: “CSV”, Output: “Detailed Record” and download,</li>
    <li>Repeat until all article entries downloaded.</li>
  </ul>
</ul>

<b><i>Analyzing Data:</i></b>
<ul>
  <li>Download and Install R -> select base option (http://cran.rstudio.com/),</li>
  <li>Download and Install RStudio (http://www.rstudio.com/products/rstudio/download/),</li>
  <li>Open RStudio anf type getwd() under console to determine working directory,</li>
  <li>Download and save data.mining.R and dm.global.R to your working directory,</li>
  <li>Type source("data.mining.R") under the console and press enter,</li>
  <li>You should initially see red text in the console, this is additional packages installing. This will only happen the first 	time you run the code. After it says installation successful, you should see a file selection window open. If not, press Alt 		+ Tab and it should show,</li>
  <li>Select the WOS or COM files that you have downloaded from the file selection window. The code will allow you to select      multiple files by holding down Shift and selecting the files. However, you can only select files from the same database (i.e.   you cannot select both COM and WOS files together). Once selected click Open,</li> 
  <li>If the file format is correct, you will then be asked to select your node type. There are four node options, enter the 			numerical value as your option (e.g. 2 for term):</li>
  <ul>
    <li><b><i>Actor</b></i> – This will extract the author names from the articles and create a co-author network. If two           authors have written a paper together then they will be linked in the network,</li>
    <li><b><i>Term</b></i> – If you enter 2 (term) and press enter you will be asked for additional input:</li>
    <ul>
      <li><b><i>Title</b></i> – unique terms will be extracted from the titles of each article and a network created. If two          words are in the same article then they will be linked in the network,</li>
      <li><b><i>Abstract</b></i> – unique terms will be extracted from the abstract of each article and a network created. If         two words are in the same article then they will be linked,</li>
      <li><b><i>Keyword</b></i> – keywords specified by the authors for each article will be used to create a network. Again, if       two keywords are in the same article they will be linked.</li>
    </ul>
    <li><b><i>Affiliation</b></i> – This will extract the affiliations of each author from each article and create a                co-affiliation network. If two authors have written a paper together from different affiliations then the affiliations will     be linked in the network,</li>
    <li><b><i>Category</b></i> – This will extract the Web of Science or Compendex categories for each article. Categories will     be linked to one another if they are from the same article.</li>
  </ul>
  <li>Once you have selected the node type, you will be asked: Do you want to plot network. If you select yes (Y) you will be 		asked for additional input:</li>
  <ul>
    <li>Plot node by – do you want to plot the nodes with the highest Degree centrality or highest Betweenness centrality?</li>
    <li>Enter number of nodes to plot – This number will specify how many nodes will be shown on the network plot, ordered from 		highest to lowest Degree/Betweenness centrality (plot node by).</li>
    <li>The final question will be whether you want to plot all edges (links between nodes). By default, edges with the lowest 			25% weights are excluded. This is done to make it easier to interpret the network plot.</li>
  </ul>
  <li>Finally, a list of results will be displayed. A summary of the network is first listed, followed by the results for each 		node. All these results will automatically be saved to a csv file in the location specified in the console under all the 				results. If you selected to plot the results, a separate window will be show that allows nodes and edges on the network to 			be adjusted.</li>
</ul>

<b><i>Additional Information</i></b>

If you want to access additional data you can type the variable name in the console. Some of the variables are:
<ul>
  <li><b><i>data</b></i> – the raw data from the downloaded files,</li>
  <li><b><i>net.stats.l</b></i> – the results for each node,</li>
  <li><b><i>net.stats.g</b></i> – the summary results for the network,</li>
  <li><b><i>mat</b></i> – the adjacency matrix (node-node matrix). If you selected term as the node type, you can find frequency   of terms and association between terms as follows (where “voltage” can be replaced with the term you want to find associations   for):</li>
  <ul>
    <li>term.freq=data.frame(termFrequency=rowSums(as.matrix(mat)))</li>
    <li>subset(term.freq, termFrequency >= 10)</li>
    <li>findAssocs(mat, "voltage", 0.25)</li>
  </ul>
  <li><b><i>net</b></i> – the network that is plotted. Simply type plot(net) to plot the network in the right panel. Type         tkplot(net) to plot interactive plot. If you want to create better looking plots, use the features from the igraph or qgraph    package.</li>
</ul>

