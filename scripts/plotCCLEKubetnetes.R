library(readr)
library(dplyr)
library(ggplot2)
library(scales)
library(reshape2)
library(extrafont)
library(magrittr)

args = commandArgs(trailingOnly=TRUE)

  waterfall_theme <- function(base_size = 20, base_family = "Roboto") {
    theme(
      line =               element_line(colour = "black", size = 0.5, linetype = 1,
                                        lineend = "round"),
      rect =               element_rect(fill = "white", colour = "black", size = 0.5, linetype = 1),
      text =               element_text(family = base_family, face = "plain",
                                        colour = "black", size = base_size,
                                        hjust = 0.5, vjust = 0.5, angle = 0, lineheight = 0.9, margin = margin(1,1,1,1), debug = FALSE),
      axis.text =          element_text(size = rel(1.2), colour = "black"),
      strip.text =         element_text(size = rel(1.2), colour = "black"),

      axis.line =          element_blank(),
      axis.text.x =        element_text(vjust = 1),
      axis.text.y =        element_blank(),
      axis.ticks.x =       element_line(size = 0.2),
      axis.ticks.y =       element_blank(),
      axis.title =         element_text(colour = "black", size = rel(1.4)),
      axis.title.x =       element_text(vjust = 1, margin = margin(t=20,b=15)),
      axis.title.y =       element_text(angle = 90, margin = margin(r=10)),
      axis.ticks.length =  unit(0.3, "lines"),

      legend.background =  element_rect(colour = NA),
      legend.margin =      unit(0.2, "cm"),
      legend.key =         element_rect(fill = "black"),
      legend.key.size =    unit(1.2, "lines"),
      legend.key.height =  NULL,
      legend.key.width =   NULL,
      legend.text =        element_text(size = rel(0.8), colour = "black"),
      legend.text.align =  NULL,
      legend.title =       element_text(size = rel(1.2), hjust = 0.5, colour = "black"),
      legend.title.align = NULL,
      legend.position =    "right",
      legend.direction =   "vertical",
      legend.justification = "right",
      legend.box =         NULL,

      panel.background =   element_rect(fill = "white", colour = NA),
      panel.border =       element_rect(fill = NA, colour = "black"),
      panel.grid.major.x = element_line(colour = "grey20", size = 0.2),
      panel.grid.major.y = element_line(colour = "grey20", size = 0.005),
      panel.grid.minor =   element_blank(),
      panel.margin =       unit(0.25, "lines"),

      strip.background =   element_rect(fill = "grey30", colour = "grey10"),
      strip.text.x =       element_text(),
      strip.text.y =       element_text(angle = -90),

      plot.background =    element_rect(),
      plot.title =         element_text(size = rel(1.8)),
      plot.margin =        unit(c(1, 1, 0.5, 0.5), "lines"),

      complete = TRUE
    )
  }

  bar_theme <- function(base_size = 20, base_family = "Roboto") {
    theme(
      line =               element_line(colour = "white", size = 0.25, linetype = 1,
                                        lineend = "round"),
      rect =               element_rect(fill = "white", colour = "white", size = 0.25, linetype = 0),
      text =               element_text(family = base_family, face = "plain",
                                        colour = "black", size = base_size,
                                        hjust = 0.5, vjust = 0.5, angle = 0, lineheight = 0.9, margin = margin(1,1,1,1), debug = FALSE),
      axis.text =          element_text(size = rel(1.2), colour = "black"),
      strip.text =         element_text(size = rel(1.2), colour = "black"),

      axis.line =          element_blank(),
      axis.text.x =        element_blank(),
      axis.text.y =        element_blank(),
      axis.ticks =         element_blank(),
      axis.title =         element_text(colour = "black", size = rel(1.4)),
      axis.title.x =       element_text(vjust = 1, margin = margin(t=20,b=15)),
      axis.title.y =       element_text(angle = 90, margin = margin(r=10)),
      axis.ticks.length =  unit(0.3, "lines"),

      legend.background =  element_rect(colour = NA),
      legend.margin =      unit(0.2, "cm"),
      legend.key =         element_blank(),
      legend.key.size =    unit(1.2, "lines"),
      legend.key.height =  NULL,
      legend.key.width =   unit(12, "lines"),
      legend.text =        element_text(size = rel(1.2), colour = "black", margin = margin(r=20,l=20)),
      legend.text.align =  0.5,
      legend.title =       element_text(size = rel(1.4), colour = "black"),
      legend.title.align = NULL,
      legend.position =    "bottom",
      legend.direction =   "horizontal",
      legend.justification = "bottom",
      legend.box =         NULL,

      panel.background =   element_rect(fill = "white", colour = NA),
      panel.border =       element_blank(),
      panel.grid.major =   element_blank(),
      panel.grid.minor =   element_blank(),
      panel.margin =       unit(0.25, "lines"),

      strip.background =   element_rect(fill = "grey30", colour = "grey10"),
      strip.text.x =       element_text(),
      strip.text.y =       element_text(angle = -90),

      plot.background =    element_rect(),
      plot.title =         element_text(size = rel(1.8), margin = margin(b=10)),
      plot.margin =        unit(c(1, 1, 0.5, 0.5), "lines"),

      complete = TRUE
    )
  }

  sar_theme <- function(base_size = 20, base_family = "Roboto", width = unit(10, "lines")) {
    theme(
      line =               element_line(colour = "black", size = 0.5, linetype = 1,
                                        lineend = "round"),
      rect =               element_rect(fill = "white", colour = "black", size = 0.5, linetype = 1),
      text =               element_text(family = base_family, face = "plain",
                                        colour = "black", size = base_size,
                                        hjust = 0.5, vjust = 0.5, angle = 0, lineheight = 0.9, margin = margin(1,1,1,1), debug = FALSE),
      axis.text =          element_text(size = rel(1.2), colour = "black"),
      strip.text =         element_text(size = rel(1.2), colour = "black"),

      axis.line =          element_blank(),
      axis.text.x =        element_text(vjust = 1),
      axis.text.y =        element_text(),
      axis.ticks.x =       element_line(size = 0.2),
      axis.ticks.y =       element_line(size = 0.2),
      axis.title =         element_text(colour = "black", size = rel(1.4)),
      axis.title.x =       element_text(vjust = 1, margin = margin(t=20,b=15)),
      axis.title.y =       element_text(angle = 90, margin = margin(r=10)),
      axis.ticks.length =  unit(0.3, "lines"),

      legend.background =  element_rect(colour = NA),
      legend.margin =      unit(0.2, "cm"),
      legend.key =         element_blank(),
      legend.key.size =    unit(1.2, "lines"),
      legend.key.height =  NULL,
      legend.key.width =   width,
      legend.text =        element_text(size = rel(1.2), colour = "black", margin = margin(r = 15)),
      legend.text.align =  0.5,
      legend.title =       element_text(size = rel(1.2), hjust = 0.5, colour = "black"),
      legend.title.align = NULL,
      legend.position =    "bottom",
      legend.direction =   "horizontal",
      legend.justification = "bottom",
      legend.box =         NULL,

      panel.background =   element_rect(fill = "white", colour = NA),
      panel.border =       element_blank(),
      panel.grid.major.x = element_line(colour = "grey20", size = 0.2),
      panel.grid.major.y = element_line(colour = "grey20", size = 0.2),
      panel.grid.minor =   element_line(colour = "grey20", size = 0.05),
      panel.margin =       unit(0.25, "lines"),

      strip.background =   element_rect(fill = "grey30", colour = "grey10"),
      strip.text.x =       element_text(),
      strip.text.y =       element_text(angle = -90),

      plot.background =    element_rect(),
      plot.title =         element_text(size = rel(1.8)),
      plot.margin =        unit(c(1, 1, 0.5, 0.5), "lines"),

      complete = TRUE
    )
  }




  all_times <- read.csv(args[1], sep="\t")
  all_times$Time <- strtrim(all_times$Time,19)
  all_times$Time <- parse_datetime(all_times$Time)
  samples <- levels(all_times$Sample)
  start <- subset(all_times,Task == 'start')$Time
  copying <- subset(all_times,Task == 'copying')$Time
  sorting <- subset(all_times,Task == 'sorting')$Time
  fastq <- subset(all_times,Task == 'fastq')$Time
  kallisto <- subset(all_times,Task == 'kallisto')$Time
  cleanup <- subset(all_times,Task == 'cleanup')$Time

  all_times <- data.frame(samples,start,copying,sorting,fastq,kallisto,cleanup)
  all_times <- all_times[order(start),]

  beginning <- all_times$start[1]

  time_since_global_beginning = function(x) (as.double(x) - as.double(beginning)) / 60.0
  time_since_sample_beginning = function(x) as.double(x['cleanup']) - as.double(x['start'])
  time_per_task = function(x,column1, column2) (as.double(x[column1]) - as.double(x[column2])) / as.double(x['run_length'])
  percent_time = function(x,column) as.double(x[column]) / as.double(x['run_length'])




  all_times$start <- sapply(all_times$start,FUN=time_since_global_beginning)

  all_times$copying <- sapply(all_times$copying,FUN=time_since_global_beginning)
  all_times$sorting <- sapply(all_times$sorting,FUN=time_since_global_beginning)
  all_times$fastq <- sapply(all_times$fastq,FUN=time_since_global_beginning)
  all_times$kallisto <- sapply(all_times$kallisto,FUN=time_since_global_beginning)
  all_times$cleanup <- sapply(all_times$cleanup,FUN=time_since_global_beginning)
  all_times$run_length <- apply(all_times, FUN=time_since_sample_beginning, MARGIN = 1)

  waterfall = data.frame(sample = all_times$sample, start = all_times$start, end = all_times$cleanup)
  waterfall$real = waterfall$start
  waterfall$length = all_times$run_length
  waterfall <- melt(waterfall, id.vars=c("sample", "real","length"), value.name="value", variable.name="Time")
  mid <- mean(waterfall$length)


  copying <- apply(all_times, FUN=time_per_task, MARGIN = 1, column1 = "copying", column2 = "start")
  sorting <- apply(all_times, FUN=time_per_task, MARGIN = 1, column1 = "sorting", column2 = "copying")
  fastq <- apply(all_times, FUN=time_per_task, MARGIN = 1, column1 = "fastq", column2 = "sorting")
  kallisto <- apply(all_times, FUN=time_per_task, MARGIN = 1, column1 = "kallisto", column2 = "fastq")
  cleanup <- apply(all_times, FUN=time_per_task, MARGIN = 1, column1 = "cleanup", column2 = "kallisto")

  percents <- data.frame(samples, copying, sorting,fastq,kallisto,cleanup)

  percents <- data.frame(task = c('Copying','Sorting','Fastq','Kallisto','Cleanup'),
                         value = c(mean(percents$copying) * 100, mean(percents$sorting) * 100, mean(percents$fastq) * 100,
                                   mean(percents$kallisto) * 100, mean(percents$cleanup) * 100 ))


  total = 0
  totals = c()
  bars = c()
  for (value in percents$value) {
    total = total + value
    totals = c(totals, total - (value / 2))
    bars = c(bars, total)
  }
  percents$position = totals
  percents$bars = bars
  percents$task <- factor(percents$task,levels(percents$task)[c(2,5,3,4,1)])

  print("Finished progress file")

  cpu <- read_tsv(paste(args[2], "cpu.tsv",sep = ""))
  mem <- read_tsv(paste(args[2], "mem.tsv",sep = ""))
  net <- read_tsv(paste(args[2], "net.tsv",sep = ""))
  disk <- read_tsv(paste(args[2], "disk.tsv",sep = ""))



# Samples over time
ggplot(data=waterfall, aes(x=value, y=reorder(sample,-real), group = sample, colour = length)) +
  geom_line() + waterfall_theme() +
  labs(x = "Time Since Start (Minutes)", y = "Sample", colour = "Running Time", title = "") +
  scale_x_continuous(breaks = seq(from = 0, to = max(waterfall$value) + 75, by = 50)) +
  scale_color_gradient(low="#65A621", high="black", space ="Lab" )

ggsave(paste(args[3],"Samples.jpeg",sep = ""), height = 285.75, width = 508, units = "mm")


# Time per Task
ggplot(percents, aes(x=0,y=value,fill=task, width=10)) +
  annotate("text", x=-6, y=percents$position, label=paste(round(percents$value,digits = 1),'%',sep = ""), size=10) +
  geom_bar(stat="identity") +
  coord_flip() +
  labs(x = "", y = "", fill = "Tasks\n", title = "") +
  bar_theme() +
  guides(fill = guide_legend(label.position = "bottom", title.position = "top", title.hjust = 0.5)) +
  scale_fill_brewer(type = "qual", palette = "Dark2", direction = 1) +
  scale_x_continuous(limits = c(-6.75,25), expand = c(0,0))

ggsave(paste(args[3],"Time.jpeg",sep = ""), height = 285.75, width = 508, units = "mm")



# CPU Graph
ggplot(data=cpu, aes(x=Time, y=Value, group=Metric, color=Metric)) +
  annotate("rect", xmin=0, xmax=percents$bars[1], ymin=0, ymax=100, fill="red", alpha=0.1) +
  annotate("rect", xmin=percents$bars[1], xmax=percents$bars[2], ymin=0, ymax=100, fill="blue", alpha=0.08) +
  annotate("rect", xmin=percents$bars[2], xmax=percents$bars[3], ymin=0, ymax=100, fill="green", alpha=0.08) +
  annotate("rect", xmin=percents$bars[3], xmax=percents$bars[4], ymin=0, ymax=100, fill="yellow", alpha=0.08) +
  annotate("rect", xmin=percents$bars[4], xmax=percents$bars[5], ymin=0, ymax=100, fill="red", alpha=0.08) +
  geom_line(size=1.2) + sar_theme() +
  labs(color = "") +
  scale_colour_manual(values = c("CPU 0" = "#579A00", "CPU 1" = "#DD027C", "CPU 2" = "#6360AA", "CPU 3" = "#CB4E00", "CPU all" = "#000000"), labels = c("CPU 0", "CPU 1", "CPU 2", "CPU 3", "All CPUs")) +
  scale_x_continuous(name = "Progress",limits = c(0,102), expand = c(0,0), breaks = seq(from = 0, to = 100, by = 10), labels = sapply(seq(from = 0, to = 100, by = 10), function(x) paste(x,'%', sep = ""))) +
  scale_y_continuous(name = "Utilization", limits = c(-1,100), expand = c(0,0), breaks = seq(from = 10, to = 100, by = 10), labels = sapply(seq(from = 10, to = 100, by = 10), function(x) paste(x,'%', sep = ""))) +
  guides(color = guide_legend(label.position = "bottom"))


ggsave(paste(args[3],"CPU.jpeg",sep = ""), height = 285.75, width = 508, units = "mm")

# Memory Graph
ggplot(data=mem, aes(x=Time, y=Value, group=Metric, color=Metric)) +
  annotate("rect", xmin=0, xmax=percents$bars[1], ymin=0, ymax=100, fill="red", alpha=0.1) +
  annotate("rect", xmin=percents$bars[1], xmax=percents$bars[2], ymin=0, ymax=100, fill="blue", alpha=0.08) +
  annotate("rect", xmin=percents$bars[2], xmax=percents$bars[3], ymin=0, ymax=100, fill="green", alpha=0.08) +
  annotate("rect", xmin=percents$bars[3], xmax=percents$bars[4], ymin=0, ymax=100, fill="yellow", alpha=0.08) +
  annotate("rect", xmin=percents$bars[4], xmax=percents$bars[5], ymin=0, ymax=100, fill="red", alpha=0.08) +
  geom_line(size=1.2) + sar_theme() +
  labs(color = "") +
  scale_colour_brewer(type = "qual", palette = "Dark2", direction = 1) +
  scale_x_continuous(name = "Progress",limits = c(0,102), expand = c(0,0), breaks = seq(from = 0, to = 100, by = 10), labels = sapply(seq(from = 0, to = 100, by = 10), function(x) paste(x,'%', sep = ""))) +
  scale_y_continuous(name = "Utilization", limits = c(-1,100), expand = c(0,0), breaks = seq(from = 10, to = 100, by = 10), labels = sapply(seq(from = 10, to = 100, by = 10), function(x) paste(x,'%', sep = ""))) +
  guides(color=FALSE)

ggsave(paste(args[3],"Memory.jpeg",sep = ""), height = 285.75, width = 508, units = "mm")

#Network Graph
ggplot(data=net, aes(x=Time, y=Value, group=Metric, color=Metric, linetype = Metric)) +
  annotate("rect", xmin=0, xmax=percents$bars[1], ymin=0, ymax=30, fill="red", alpha=0.1) +
  annotate("rect", xmin=percents$bars[1], xmax=percents$bars[2], ymin=0, ymax=30, fill="blue", alpha=0.08) +
  annotate("rect", xmin=percents$bars[2], xmax=percents$bars[3], ymin=0, ymax=30, fill="green", alpha=0.08) +
  annotate("rect", xmin=percents$bars[3], xmax=percents$bars[4], ymin=0, ymax=30, fill="yellow", alpha=0.08) +
  annotate("rect", xmin=percents$bars[4], xmax=percents$bars[5], ymin=0, ymax=30, fill="red", alpha=0.08) +
  geom_line(size=1.2) + sar_theme(width = unit(15,"line")) +
  labs(color = "") +
  scale_colour_brewer(type = "qual", palette = "Dark2", direction = -1) +
  scale_x_continuous(name = "Progress",limits = c(0,102), expand = c(0,0), breaks = seq(from = 0, to = 100, by = 10), labels = sapply(seq(from = 0, to = 100, by = 10), function(x) paste(x,'%', sep = ""))) +
  scale_y_continuous(name = "Transfer Speed (MB/s)", limits = c(-0.5,30), expand = c(0,0), breaks = seq(from = 5, to = 30, by = 5)) +
  scale_linetype_manual(values = c(1,5)) +
  guides(linetype=FALSE, color = guide_legend(label.position = "bottom"))

ggsave(paste(args[3],"Network.jpeg",sep = ""), height = 285.75, width = 508, units = "mm")

# Disk Graph
ggplot(data=disk, aes(x=Time, y=Value, group=Metric, color=Metric, linetype = Metric)) +
  annotate("rect", xmin=0, xmax=percents$bars[1], ymin=0, ymax=50, fill="red", alpha=0.1) +
  annotate("rect", xmin=percents$bars[1], xmax=percents$bars[2], ymin=0, ymax=50, fill="blue", alpha=0.08) +
  annotate("rect", xmin=percents$bars[2], xmax=percents$bars[3], ymin=0, ymax=50, fill="green", alpha=0.08) +
  annotate("rect", xmin=percents$bars[3], xmax=percents$bars[4], ymin=0, ymax=50, fill="yellow", alpha=0.08) +
  annotate("rect", xmin=percents$bars[4], xmax=percents$bars[5], ymin=0, ymax=50, fill="red", alpha=0.08) +
  geom_line(size=1.2) + sar_theme(width = unit(20, "lines")) +
  labs(color = "") +
  scale_colour_brewer(type = "qual", palette = "Dark2", direction = -1) +
  scale_x_continuous(name = "Progress",limits = c(0,102), expand = c(0,0), breaks = seq(from = 0, to = 100, by = 10), labels = sapply(seq(from = 0, to = 100, by = 10), function(x) paste(x,'%', sep = ""))) +
  scale_y_continuous(name = "Transfer Speed (MB/s)",limits = c(-0.5,50), expand = c(0,0), breaks = seq(from = 10, to = 50, by = 10)) +
  scale_linetype_manual(values = c(5,1,5,1)) +
  guides(linetype=FALSE, color = guide_legend(label.position = "bottom"))

ggsave(paste(args[3],"Disk.jpeg",sep = ""), height = 285.75, width = 508, units = "mm")
