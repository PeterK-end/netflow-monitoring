library("tidyverse")
library("kableExtra")

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

ggplot(data = nfcapd_data, mapping = aes(x = ts, y = byt)) +
    geom_area()

# With which IP Icommunicate with the most?

df_top_hosts <- nfcapd_data %>%
    group_by(da) %>%
    summarise(sum_Mbyt = sum(byt)/1000000) %>%
    slice_max(n = 20, order_by = sum_Mbyt) %>%
    mutate(domain= map_chr(da, ~ {
        ns_response <- system(paste("nslookup ", .x), intern=TRUE)

        if (length(ns_response) < 3) {
            return("None")
        } else {
            print(ns_response)
            tname <- ns_response[str_detect(ns_response, "\tname =")]
            print(tname)
            return(str_split(tname, "= ")[[1]][2])
        }
    }))

kable(df_top_hosts,
      format = "latex",
      col.names = c("Host IP-Address", "MByte Volume", "tname"))
