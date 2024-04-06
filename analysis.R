library(tidyverse)

nfcapd_data <- read_csv("aggregated_capture.csv",
                         skip = 1,
                         col_names = c("sa", "da", "ts",  "td", "pr", "sp", "dp", "pkt", "byt", "bps", "pps")) %>%
    mutate(hour = hour(ts),
           day = day(ts),
           bps = if_else(str_detect(bps, "M"),
                         true = str_replace(bps, "M", "") %>% as.numeric %>% `*`(1000000),
                         false = as.numeric(bps)))

# very low because of low byt entries
ggplot(data = group_by(nfcapd_data, hour, day) %>% summarise(avg_bps = mean(byt)/60/60),
       mapping = aes(x = hour, y = avg_bps)) +
    geom_area(alpha = 0.5) +
    geom_point(color = "red") +
    facet_wrap(~day)

# TODO: make some
ggplot(data = group_by(nfcapd_data, hour, day) %>% summarise(bps = sum(bps)/60/60),
       mapping = aes(x = hour, y = bps)) +
    geom_area(alpha = 0.5) +
    geom_point(color = "red") +
    #geom_boxplot() +
    #geom_point(aes(x = hour, y = avg_bps), color = "red") +
    facet_wrap(~day)
