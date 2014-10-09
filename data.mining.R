#-------------------------------------------------------------------#
# This code requests user input, downloads the files, and calls functions
# from dm.global.R for analyzing the data
#-------------------------------------------------------------------#

# Load required functions and lists
source("dm.global.R")

# -------------------START OF USER INPUTs----------------------------#
# Allow user to select file location
# file.loc <- file.choose()
file.loc <- choose.files()

if (length(file.loc) > 0) {
  # file.loc <- readline(cat("Enter the location of your Web of Science or Compendex csv file:\n"))
  # Determine number of Web of Science Files
  wos.files <- which(sapply(file.loc, function(x) substr(x, nchar(x)-2, nchar(x)) == "txt"))
  # Determine number of Compendex Files
  com.files <- which(sapply(file.loc, function(x) substr(x, nchar(x)-2, nchar(x)) == "csv"))
  # Only allow the selection of flies from one database, not both
  if (length(wos.files) > 0 && length(com.files) > 0)
    stop("Select either Web of Science or Compendex Files, not both")
  
  data <- data.frame()
  if (length(wos.files) > 0)
    for (i in wos.files) {
      tryCatch(data.tmp <- read.table(file.loc[i], sep="\t", quote="", header=T, encoding = "UTF-8", na.string = NA, 
                                      comment.char = "", fill = TRUE, blank.lines.skip = TRUE, row.names=NULL, 
                                      stringsAsFactors = FALSE),
               error = function(e) stop("Error opening/reading txt file. Ensure Web Of Science file downloaded according to description: ", e))
      c.names <- colnames(data.tmp)
      colnames(data.tmp) <- c("PT", colnames(data.tmp)[-1:-2])
      data <- rbind(data, data.tmp)                        
    }
  
  if (length(com.files) > 0)
    for (i in com.files) {
      # Read Web of Science (wos) or Compendex(com) file. If error occurs reading
      # the file, return error
      tryCatch(data.tmp <- read.csv(file.loc[i], stringsAsFactors = FALSE),
               error = function(e) stop("Error opening/reading csv file. Ensure Compendex file downloaded according to description: ", e))
      data <- rbind(data, data.tmp) 
    }
  data <- unique(data)
  # Select either [1] actor, [2] term, [3] affiliation, [4] category  
  # for the type of node
  node.type <- node.type.l[1]
  node.type.s <- paste0("[", 1:length(node.type.l), "] ", node.type.l)
  # Ask user to select node type
  node.type.i <- as.numeric(readline(cat("Enter node type by number:", paste(node.type.s, collapse=", "), "\n")))
  # If invalid value entered, use [1] title as the default value
  if (is.na(node.type.i) || node.type.i > 4 || node.type.i < 1) {
    node.type.i <- 1
    warning("Invalid value entered. [1] actor selected as default", call. = FALSE)
  }
  node.type <-node.type.l[node.type.i] 
  
  # If using term node type, select the column to use to extract terms
  # [1] title, [2] abstract, [3] keyword
  term.type <- term.type.l[1]
  term.type.s <- paste0("[", 1:length(term.type.l), "] ", term.type.l)
  if (node.type == "term") {
    # Ask user to select term type
    term.type.i <- as.numeric(readline(cat("Enter term type by number:", paste(term.type.s, collapse=", "), ". Abtract takes a few minutes\n")))
    # If invalid value entered, use [1] title as the default value
    if (is.na(term.type.i) || term.type.i > 3 || term.type.i < 1) {
      term.type.i <- 1
      warning("Invalid value entered. [1] title selected as default", call. = FALSE)
    }
    term.type <- term.type.l[term.type.i] 
  }
  
  # Specify which weighting function to use for the term-document matrix if 
  # term selected as node.type.
  term.weight <- term.weight.l[2]
  # Specify the minimum term length to include in the matrix
  term.length <- 3
  
  # Ask user whether to plot results or not
  plot.result <- readline(cat("Do you want to plot network: (Y)/(N)\n"))
  # Convert response to binary
  plot.result.b <- ifelse(tolower(plot.result) == "y", TRUE, FALSE)
  # If user wants to plot results, ask what metric to plot by: [1] Degree, [2] Betweenness
  if (plot.result.b) {
    plot.by <- as.numeric(readline(cat("Plot nodes by: [1] Degree, [2] Betweenness")))
    # If invalid value entered, use [2] Betweenness as the default value
    if (is.na(plot.by) || plot.by > 2 || plot.by < 1) {
      plot.by <- 2
      warning(paste("Invalid value entered. [2] Betweenness selected as default"), call. = FALSE)
    }
    # Convert response to actual name
    plot.by <- ifelse(plot.by == 1, "InDegree", "Betweenness")
    
    # Ask user how many nodes to plot
    plot.count <- as.numeric(readline(cat("Enter number of nodes to plot. Keep below 50, otherwise plot is", 
                                          "difficult to interpret and slow\n")))
    # If invalid value entered, use 20 as the default value
    if (is.na(plot.count)) {
      plot.count <- 20
      warning("Invalid number of nodes entered. Max of 20 selected as default", call. = FALSE)
    }
    # Restrict response to less than or equal to 50 but greater than 1
    if (plot.count > 50) {
      plot.count <- 50
      warning("Number of nodes limited to 50 for plot", call. = FALSE)
    } else
      if (plot.count < 1)
        plot.count <- 1
    # Ask user whether to plot all edges. Edges are remove by default to make it
    # easier to interpret the plot
    plot.edges <- readline(cat("Do you want to plot all edges. If yes, it may be difficult to
                              intepret the network: (Y)/(N)\n"))
    # Convert response to binary
    plot.edges.b <- ifelse(tolower(plot.edges) == "y", TRUE, FALSE)
  }
  # -------------------END OF USER INPUTs----------------------------#  
  
  # -----------------START OF EXTRACTING DATA------------------------# 
  # Check the first column name to see whether the file is from wos or com
  switch(colnames(data)[1],
         'PT' =  db <- db.l[1],
         'Title' = db <- db.l[2],
         stop("Ensure file downloaded in csv format from either Compendex or Web of Science")) 
  
  # Extract the nodes from the data
  nodes <- extract.nodes(data, db, node.type, term.type)
  
  # Create the Node-Document matrix
  mat <- create.matrix(nodes, node.type, term.length, term.weight)
  
  # Create SNA network 
  net <- create.network(mat)
  
  # Results for individual nodes
  net.stats.l <- data.frame(InDegree = degree(net, mode="in"), Betweenness = betweenness(net), 
                            Closeness = closeness(net), EigenVector = evcent(net)$vector, 
                            Local.Cluster = transitivity(net, type = "local"))
  # Results for network
  net.stats.g <- data.frame(Nodes = length(V(net)), Edges = length(E(net)), 
                            Density = graph.density(net), 
                            Global_Cluster = transitivity(net, type="global"), 
                            Edge_Connectivity = edge.connectivity(net), 
                            Adhesion = graph.adhesion(net))
  
  # -----------------END OF EXTRACTING DATA------------------------# 
  
  # Display summary of results
  print("#----------------------NETWORK SUMMARY------------------------#")
  print(net.stats.g)
  # Write network summary results to csv file
  tryCatch({ write.csv(net.stats.g, file = "net.stats.g.csv")
             print(paste("Files saved to", getwd())) },
           error = function(e) {
             warning(paste("Could not write network summary data to csv. Ensure write access",
                           "is allowed for", getwd(), "and that the file net.stats.g.csv is closed. Type",
                           "write.csv(net.stats.g, file = 'net.stats.g.csv') to save results."), call. = FALSE)
           }) 
  
  # Show results for individual nodes
  print("#----------------------NODE SUMMARY---------------------------#")
  # Write individual network results to csv file
  print(head(net.stats.l[order(net.stats.l[, plot.by], decreasing = TRUE), ], min(plot.count, nrow(net.stats.l))))
  # Write individual network results to csv file
  tryCatch({ write.csv(net.stats.l, file = "net.stats.l.csv")
             print(paste("Files saved to", getwd())) },
           error = function(e) {
             warning(paste("Could not write network summary data to csv. Ensure write access",
                           "is allowed for", getwd(), "and that the file net.stats.l.csv is closed. Type",
                           "write.csv(net.stats.l, file = 'net.stats.l.csv') to save results."), call. = FALSE)
           }) 
  
  # Plot network (Due to large amount of nodes this is really slow, so restricted to 50 nodes)
  if (plot.result.b) {
    # Select nodes with the highest 'plot.by' selection (Degree or Betweenness). Select first 'plot.count' nodes
    high.nodes <- order(net.stats.l[, plot.by], decreasing = TRUE)[1:min(plot.count, nrow(net.stats.l))]
    net.s <- delete.vertices(net, V(net)[!(1:nrow(net.stats.l) %in% high.nodes)])
    if (plot.by == "InDegree")
      v.size <- degree(net.s, mode="in")
    else
      v.size <- betweenness(net.s)
    v.size <- ifelse(max(v.size) == 0, 1, (v.size/max(v.size)) * 20)
    e.size <- (E(net.s)$weight/max(E(net.s)$weight)) * 4
    if (!plot.edges.b)
      net.s <- delete.edges(net.s, E(net.s)[e.size <= 1])
    V(net.s)$size <- v.size
    V(net.s)$label.cex <- 1
    V(net.s)$label.color <- "black"
    V(net.s)$color <- "#D2691E"
    E(net.s)$width <- e.size
    E(net.s)$color <- "steelblue"
    tkplot(net.s, canvas.width=800, canvas.height=800, layout = layout.kamada.kawai)
  }
}
