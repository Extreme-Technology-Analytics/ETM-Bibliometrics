#-------------------------------------------------------------------#
# This code contains all the functions used in data.mining.R for extracting
# the nodes from the data, creating an adjacency matrix, and using this 
# matrix to create a network.
#-------------------------------------------------------------------#

# Install required packages
packages <- c("tm", "igraph", "stringr")
if (length(setdiff(packages, installed.packages())) > 0)
  install.packages(setdiff(packages, installed.packages()))

# tm package required for creating term-document matrix
library(tm)
# igraph package required for creating sna plot
library(igraph)
# stringr package used for trimming text
library(stringr)

# Data can currently only be read from web of science (wos) or Compendex (com) database
db.l <- c('wos', 'com')
# The node for the network can either be an author (actor) or a term
node.type.l <- c("actor", "term", "affl", "category")
# term can be extracted from either the title, the abstract, or author keywords
term.type.l <- c("title", "abstract", "keyword")
# character seperating node data
sep.l <- c("", " ", ",", ";", "\t", "-")
# Weighting function to use for term-document matrix
term.weight.l <- c('nnn', 'ntc')

# Extract Relevant Node Data
extract.nodes <- function(data, db = "wos", node.type = "actor", term.type = "title", stem = FALSE) {
  # Determine which column from the data to select, specify the 
  # character seperating the nodes, and specify a regular expression
  # for removing unwanted characters
  if (db == "wos") {
    node.col <- switch(node.type,
                       actor = "AU",
                       term = switch(term.type, title = "TI", abstract = "AB", keyword = "DE"),
                       affl = "C1",
                       category = "WC")
    node.sep <- sep.l[4]
    node.reg <- ifelse(node.type == "affl", "\\s*\\[(.*?)\\]\\s*", "\\.+\\s*")
  } else {
    node.col <- switch(node.type,
                       actor = "Author",
                       term = switch(term.type, title = "Title", abstract = "Abstract", 
                                     keyword = c("Controlled.Subject.terms")),
                       affl = "Author.affiliation",
                       category = "Classification.code")
    node.sep <- switch(node.type, 
                       affl = "\\s+\\([0-9]+\\)\\s*",
                       category = "\\s*-\\s*",
                       sep.l[4])
    node.reg <- switch(node.type,
                       affl = "^\\([0-9]+\\)\\s*", 
                       "\\s*\\([0-9]+\\)\\s*")
  }
  # Extract actors or terms from specified columns of data
  nodes <- switch(node.type,
                  term = {
                    # Create corpus using specified data and clean up terms
                    nodes.tmp <- Corpus(VectorSource(data[, node.col]))
                    nodes.tmp <- tm_map(nodes.tmp, tolower)
                    nodes.tmp <- tm_map(nodes.tmp, removePunctuation)
                    nodes.tmp <- tm_map(nodes.tmp, removeNumbers)
                    nodes.tmp <- tm_map(nodes.tmp, removeWords, stopwords('english'))
                    removeURL <- function(x) gsub("http[[:alnum:]]*", "", x)
                    nodes.tmp <- tm_map(nodes.tmp, removeURL)
                    nodes.tmp <- tm_map(nodes.tmp, stripWhitespace)
#                     if (stem) {
#                       nodes.tmp.s <- tm_map(nodes.tmp, stemDocument)
#                       nodes.tmp <- tm_map(nodes.tmp.s, stemCompletion, dictionary=nodes.tmp)
#                     }
                    
                    tm_map(nodes.tmp, PlainTextDocument)
                  },
                  {
                    nodes.tmp <- gsub(node.reg, "", data[, node.col]) 
                    # Split the nodes by the specified character
                    nodes.tmp <- strsplit(nodes.tmp, split = node.sep)
                    # Remove additional characters using the specified regular expression
                    lapply(nodes.tmp, function(x) gsub(node.reg, "", str_trim(unlist(x))))
                  })
  return(nodes) 
}

# Create the Node-Document matrix
create.matrix <- function(nodes, node.type = "actor", term.minlength = 1, term.weight = "ntc", match.max = 0.10, clean.str = "dpto|dept|department"){
  mat <- switch(node.type,
                term = suppressWarnings(TermDocumentMatrix(nodes, control=list(wordLengths = c(term.minlength, Inf),
                                                              weighting = function(x) weightSMART(x, spec=term.weight)))),
                {
                  # Determine number of nodes per document
                  nodes.per.doc <- sapply(nodes, function(x) length(x))
                  # Create list of document numbers for each node 
                  nodes.doc.no <- rep(1:length(nodes.per.doc), times = nodes.per.doc)
                  nodes.unlist <- unlist(nodes)
                  # Determine number of nodes
                  node.count <- length(nodes.unlist)
                  nodes.unlist <- sapply(strsplit(nodes.unlist, ","), 
                                         function(x) {
                                            match <- grep(clean.str, x, ignore.case = TRUE)
                                            if (length(match) > 0)
                                              paste(str_trim(x[-match]), collapse=",")
                                            else
                                              paste(str_trim(x), collapse=",")
                                          })
                  # Determine string lengths for each node, determine the max length for each adist comparison
                  mat.strlen <- t(matrix(str_length(nodes.unlist), nrow = node.count, ncol = node.count))
                  mat.strlen <- matrix(pmax(diag(mat.strlen), mat.strlen), nrow = node.count)
                  match.b <- adist(nodes.unlist, nodes.unlist, ignore.case = TRUE)/mat.strlen < match.max
                  # Determine which nodes match
                  node.match <- apply(match.b, 1, function(x) which(x))
                  node.match.unq <- node.match[!duplicated(node.match)]
                  # Determine document numbers for matching nodes
                  node.match.doc <- lapply(node.match.unq, function(x) nodes.doc.no[x])
                  
                  # Create nodes/document matrix
                  mat.tmp <- matrix(0, nrow = length(node.match.doc), ncol = length(nodes), 
                                    dimnames = list(nodes.unlist[!duplicated(node.match)], 1:length(nodes)))
                  for (i in 1:nrow(mat.tmp))
                    mat.tmp[i, node.match.doc[[i]]] <- 1
  
                  mat.tmp
                })
  return(mat)
}

create.network <- function(mat, weighted = TRUE, mode = "undirected"){
  mat <- as.matrix(mat)
  mat.adj <- mat %*% t(mat)
  graph <- graph.adjacency(mat.adj, weighted = weighted, mode = mode)
  graph <- simplify(graph)
  V(graph)$label <- V(graph)$name
  V(graph)$degree <- degree(graph)
  return(graph)
} 
