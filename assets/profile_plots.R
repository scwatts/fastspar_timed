#!/usr/bin/env Rscript


### Libraries
library(ggplot2)
library(reshape2)


### Data
# Load data
d.time <- read.table('compiled_time.tsv', header=TRUE, stringsAsFactors=FALSE)
d.memory <- read.table('compiled_memory.tsv', header=TRUE, stringsAsFactors=FALSE)

header_tokens <- c('dataset', 'Samples', 'OTUs', 'FastSpar (single thread)', 'FastSpar (16 threads)', 'SparCC')
colnames(d.memory) <- header_tokens
colnames(d.time) <- header_tokens

# Melt data frame and convert to minute units
d.time.melt <- melt(d.time, id.vars=c('dataset', 'Samples', 'OTUs'), variable.name='Method', value.name='time')
d.time.melt$time <- d.time.melt$time / 60

d.memory.melt <- melt(d.memory, id.vars=c('dataset', 'Samples', 'OTUs'), variable.name='Method', value.name='memory')
d.memory.melt$memory <- d.memory.melt$memory / (1024^2)

# We only need to show memory comparison between SparCC and single thread FastSpar
d.memory.melt <- d.memory.melt[d.memory.melt$Method!='FastSpar (16 threads)', ]


# Rename sample column for facets (must order factor)
name_map.samples <- sapply(seq(250, 2500, 250), sprintf, fmt='%d samples')
names(name_map.samples) <- seq(250, 2500, 250)
d.time.melt$samples_facet <- name_map.samples[as.character(d.time.melt$Samples)]
d.memory.melt$samples_facet <- name_map.samples[as.character(d.memory.melt$Samples)]

{
  order <- order(d.time.melt$Samples)
  levels <- unique(as.character(d.time.melt$samples_facet[order]))
  d.time.melt$samples_facet <- factor(d.time.melt$samples_facet, levels=levels)
}
{
  order <- order(d.memory.melt$Samples)
  levels <- unique(as.character(d.memory.melt$samples_facet[order]))
  d.memory.melt$samples_facet <- factor(d.memory.melt$samples_facet, levels=levels)
}


# Linear models
fastspar.memory.lm <- lm(sqrt(d.memory$`FastSpar (single thread)`) ~ d.memory$OTUs + d.memory$Samples)
fastspar.time.lm <- lm(sqrt(d.time$`FastSpar (16 threads)`) ~ d.time$OTUs + d.time$Samples)
summary(fastspar.memory.lm)
summary(fastspar.time.lm)


### Plot
png(filename='plots/comparison_full_time.png', height=1000, width=1400, res=160)
{
g <- ggplot(d.time.melt, aes(x=OTUs, y=time, colour=Method)) + geom_line() + facet_wrap(nrow=2, ~ samples_facet)
g <- g + theme(axis.text.x = element_text(angle=45, hjust=1))
g <- g + xlim(0, 2500)
g <- g + scale_colour_manual(values=c("#619CFF", "#00BA38", "#F8766D"))
g <- g + labs(x='OTU number', y='Wall time (minutes)', colour='Method')
g
}
dev.off()

png(filename='plots/comparison_full_memory.png', height=1000, width=1400, res=160)
{
g <- ggplot(d.memory.melt, aes(x=OTUs, y=memory, colour=Method)) + geom_line() + facet_wrap(nrow=2, ~ samples_facet)
g <- g + xlim(0, 2500)
g <- g + scale_colour_manual(values=c("#619CFF", "#F8766D"))
g <- g + theme(axis.text.x = element_text(angle=45, hjust=1))
g <- g + labs(x='OTU number', y='Wall time (minutes)', colour='Method')
g
}
dev.off()

# Summarised
png(filename='plots/comparison_summary_time.png', height=1080, width=1920, res=220)
{
  g <- ggplot(d.time.melt, aes(x=factor(OTUs), y=time, colour=Method)) + geom_boxplot(width = 0.25)
  g <- g + scale_colour_manual(values=c("#619CFF", "#00BA38", "#F8766D"))
  g <- g + labs(title='A', x='OTUs', y='Wall time (minutes)')
  g
}
dev.off()

png(filename='plots/comparison_summary_memory.png', height=1080, width=1920, res=220)
{
  g <- ggplot(d.memory.melt, aes(x=factor(OTUs), y=memory, colour=Method)) + geom_boxplot(width = 0.25)
  g <- g + scale_colour_manual(values=c("#619CFF", "#F8766D"))
  g <- g + labs(title='B', x='OTUs', y='Memory (GB)')
  g
}
dev.off()
