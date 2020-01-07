# rewritten as a function
qiime2phylo <- function(qiime_OTU, qiime_TAX, qiime_tree, mapping_file) {

  library(phyloseq)
  library(ggplot2)
  library(ape)

  OTU <- qiime_OTU
  TAX <- qiime_TAX
  metadata <- mapping_file
  phy_tree <- qiime_tree
  OTU_sub <- data.frame(lapply(OTU, function(x) {
    gsub("#OTU ID", "OTUID", x)}))
  View(OTU_sub)
  OTU <- OTU_sub

  # 5.2 remove "# constructed from biom" false header
  OTU <- OTU[-1,]

  # 5.3  set sample IDs as column names
  colnames(OTU) <- as.character(unlist(OTU[1,]))
  OTU = OTU[-1, ]
  sapply(OTU, class)

  # reassign NA
  OTU[OTU == "0.0"] <- NA
  OTU[is.na(OTU)] <- 0


  TAX_sub <- data.frame(lapply(TAX, function(x) {
    gsub("Feature ID", "OTUID", x)}))

  #View(TAX_sub)
  TAX <- TAX_sub

  #6.2  set sample IDs as column names so you can merge
  colnames(TAX) <- as.character(unlist(TAX[1,]))
  TAX = TAX[-1, ]
  View(TAX)

  # 7 merge OTU and taxonomy drops empty taxonomy for OTUs not present in the sample.
  # If this step errors make sure that TAX[1,1] and OTU[1,1] both read "OTUID" and that
  merged_file <- merge(OTU, TAX, by.x = c("OTUID"), by.y = c("OTUID"))
  head(merged_file)
  View(merged_file)

  # 8 make otu_table
  remove_taxa <- c("Taxon", "Confidence")
  otu_table <- merged_file[ , !(names(merged_file) %in% remove_taxa)]
  head(otu_table)
  View(otu_table)
  sapply(otu_table, class)

  # 9 make a taxonomy file that phyloseq can read.
  taxonomy <- merged_file %>% select(OTUID, Taxon)
  View(taxonomy)

  # 10 seperate out taxonomy
  ranks = c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
  taxonomy <- separate(taxonomy, 2, ranks,sep = ";")
  View(otu_table)
  View(taxonomy)
  #exporting taxonomy and otu in table format to preserve formatting
  write.csv(taxonomy, "taxonomy.csv", row.names = FALSE)
  write.csv(otu_table, "otu_table.csv", row.names = FALSE)


  # 11 read in the otu_table.csv and taxonomy.csv files created in the earlier steps.
  # read otu
  otu_data <- read.csv("otu_table.csv", stringsAsFactors = FALSE, header = TRUE)
  sapply(otu_data, class)
  # update sample names
  names(otu_data) <- names(otu_table)

  # set rownames
  rownames(otu_data) <- otu_data[,1]
  otu_data <- otu_data[,-1]

  # make sure data is numeric
  sapply(otu_data, class)
  # read in otu as matrix
  otu_data <- as.matrix(otu_data)
  View(otu_data)
  # read taxonomy
  taxonomy <- read.csv("taxonomy.csv", stringsAsFactors = FALSE, header = TRUE, row.names = 1)
  View(taxonomy)
  # read in taxonomy as matrix
  taxonomy <- as.matrix(taxonomy)


  # 12  read metadata (mapping file)
  metadata <- mapping_file

  # 13  read qiime export tree (from step 4)
  phy_tree <- qiime_tree

  # 14  import as phyloseq objects
  OTU <- otu_table(otu_data, taxa_are_rows = TRUE)
  TAX <- tax_table(taxonomy)
  META <- sample_data(metadata)
  # check that sample names align between the OTU and metadata
  cat(sample_names(OTU), "\n\nthe sample IDs above are OTU ID's and should match these sample ID's from taxonomy: \n", sample_names(META))

  # 15 merge into a physeq object for analysis in library(phyloseq)
  physeq <- phyloseq(OTU, TAX, META, phy_tree)
}
qiime2phylo(OTU1, TAX, phy_tree, mapping_file)