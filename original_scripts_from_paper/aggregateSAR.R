library(readr)
library(dplyr)

args = commandArgs(trailingOnly=TRUE)

print("Reading Activity")
sar <- read_tsv(args[1])
print("Finished Reading Activity")
sar %>% select(Sample, `Time Since Start`) %>% group_by(Sample) %>% summarize(Total=max(`Time Since Start`)) -> sarMaxPerSample
inner_join(sar, sarMaxPerSample) -> sar
colnames(sar) <- c("Sample","Time.Since.Start","Metric","Value","Total")
print("Finished adding Total Column")

getPercent <- function(x,y) round(as.double(x['Time.Since.Start']) / as.double(x['Total']), y) * 100
toMB <- function(x) as.double(x['Value']) / 1024

print("Filtering subsets")
num_cpu <- c("CPU all")
for (i in 0:(as.integer(args[2]) - 1)) {
  num_cpu <- c(num_cpu, paste("CPU", i, sep = " "))
}

cpu <- filter(sar, Metric %in% num_cpu)
print("CPU DONE")
mem <- filter(sar, Metric %in% c("memused"))
print("Mem Done")
net <- filter(sar, Metric %in% c("Recieved", "Transmitted"))
print("Network Done")
disk <- filter(sar,Metric %in% c("Main Disk Read", "Main Disk Write", "Secondary Disk Read", "Secondary Disk Write"))
print("Disk Done")
print("Getting Percentages")
cpu$Time.Since.Start <- apply(cpu, 1, getPercent, y=3)
print("CPU DONE")

mem$Time.Since.Start <- apply(mem, 1, getPercent, y=4)
print("Mem Done")

net$Time.Since.Start <- apply(net, 1, getPercent, y=4)
print("Network Done")

disk$Time.Since.Start <- apply(disk, 1, getPercent, y=3)
print("Disk Done")

print("Aggregating")
cpu <- aggregate(cpu$Value, by=list(cpu$Time.Since.Start, cpu$Metric), mean)
print("CPU DONE")

mem <- aggregate(mem$Value, by=list(mem$Time.Since.Start, mem$Metric), mean)
print("Mem Done")

net <- aggregate(net$Value, by=list(net$Time.Since.Start, net$Metric), mean)
print("Network Done")

disk <- aggregate(disk$Value, by=list(disk$Time.Since.Start, disk$Metric), mean)
print("Disk Done")



colnames(cpu) <- c("Time", "Metric", "Value")
colnames(mem) <- c("Time", "Metric", "Value")
colnames(net) <- c("Time", "Metric", "Value")
colnames(disk) <- c("Time", "Metric", "Value")

net$Value <- apply(net, 1, toMB)
disk$Value <- apply(disk, 1, toMB)
print("Writing files")
write_tsv(cpu, paste(args[3],"cpu.tsv",sep = ""))
write_tsv(mem, paste(args[3],"mem.tsv",sep = ""))
write_tsv(net, paste(args[3],"net.tsv",sep = ""))
write_tsv(disk, paste(args[3],"disk.tsv",sep = ""))
