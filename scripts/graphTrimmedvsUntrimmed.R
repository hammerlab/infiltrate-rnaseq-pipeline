library(readr)

args <- commandArgs(trailingOnly = TRUE)

trimmed <- as.data.frame(read_tsv(args[1]))
untrimmed <- as.data.frame(read_tsv(args[2]))

trimmed.log <- log2(trimmed[,2:ncol(trimmed)])
untrimmed.log <- log2(untrimmed[,2:ncol(untrimmed)])

rownames(trimmed.log) <- trimmed[,1]
rownames(untrimmed.log) <- untrimmed[,1]


spearman <- c(1:(ncol(trimmed.log)))
for(i in 1:ncol(trimmed.log)) {
    spearman[i] <- cor(trimmed.log[,i],untrimmed.log[,i],method = "spearman")
}

pdf(args[3])
hist(spearman)

indices_to_plot = c(sort(spearman, decreasing = TRUE, index.return = TRUE)$ix[1:3], sort(spearman, decreasing = FALSE, index.return = TRUE)$ix[1:3])

for (index in indices_to_plot) {
    plot(trimmed.log[,index], untrimmed.log[,index], main = colnames(trimmed.log)[index], sub = paste("Spearman: ",spearman[index]), xlab = "Trimmed", ylab = "Untrimmed")
}

dev.off()
