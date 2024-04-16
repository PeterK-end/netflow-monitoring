library("tidyverse")
library("kableExtra")

nfcapd_data <- read_csv("aggregated_capture.csv",
                         skip = 1,
                         col_names = c("sa", "da", "ts",  "td", "pr", "sp", "dp", "pkt", "byt", "bps", "pps")) %>%
    mutate(hour = hour(ts),
           day = day(ts),
           day = case_when(day == 2 ~ "2. April", day == 3 ~ "3. April", day == 4 ~ "4. April"),
           bps = if_else(str_detect(bps, "M"),
                         true = str_replace(bps, "M", "") %>% as.numeric %>% `*`(1000000),
                         false = as.numeric(bps))) %>%
    drop_na(byt, pkt, da)

# very low because of low byte entries
plot_bytes <- ggplot(data = group_by(nfcapd_data, hour, day) %>% summarise(bph = sum(byt)/1000000),
                     mapping = aes(x = hour, y = bph)) +
    geom_col() +
    facet_wrap(~day) +
    labs(y = "Mbytes Total", x = "Hour") +
    theme(text = element_text(size = 20))

plot_packets <- ggplot(data = nfcapd_data,
                       mapping = aes(x = hour, y = sum(pkt))) +
    geom_col() +
    facet_wrap(~day) +
    labs(y = "Packets Total", x = "Hour") +
    theme(text = element_text(size = 20))

ggsave(plot = plot_bytes,
       filename = "plot_bytes.pdf")

ggsave(plot = plot_packets,
       filename = "plot_packets.pdf")

# With which IP Icommunicate with the most?

df_top_hosts <- nfcapd_data %>%
    summarise(sum_Mbyt = round(sum(byt)/1000000, 2)) %>%
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

# save latex table
sink("top_hosts.tex")
kable(df_top_hosts,
      format = "latex",
      col.names = c("Host IP-Address", "MByte Total", "Domain"),
      caption = "Top 20 destinations based on number of transmitted bytes")
sink()


# Top 3 destination Autonomous systems

df_meta <- map_df(unique(filter(nfcapd_data, !str_detect(da, "^255|^ff|^10\\.|^127"))$da), # filtering broad- and multicast
                  ~{
                      whois_response <- system(paste("whois ", .x), intern=TRUE)
                      origin_line <- whois_response[str_detect(whois_response, "origin|OriginAS")]
                      country_line <- whois_response[str_detect(whois_response, "[Cc]ountry")]
                      netname <- whois_response[str_detect(whois_response, "netname")]
                      if(length(origin_line) == 0) origin_line <- ""
                      if(length(country_line) == 0) country_line <- ""
                      if(length(netname) == 0) country_line <- ""
                      return(tibble(da = .x,
                                    as = str_extract(origin_line[1], "AS[:digit:]+"),
                                    cntry = str_extract(country_line[1], "(?<=\\:).*") %>% str_squish,
                                    netname = str_extract(netname[1], "(?<=\\:).*") %>% str_squish ))
                  })

# save data frame to disk
#saveRDS(df_meta, "df_meta.RDS")
#df_meta <- readRDS("df_meta.RDS")

df_top_as <- nfcapd_data %>%
    left_join(df_meta, by = "da") %>%
    drop_na(as) %>%
    group_by(as, cntry, netname) %>%
    summarise(sum_Mbyte = round(sum(byt)/1000000, 2)) %>%
    arrange(-sum_Mbyte) %>%
    head(5)

sink("top_as.tex")
print(kable(df_top_as,
            format = "latex",
            col.names = c("AS", "Country", "Network Name", "Mbyte total"),
            caption = "Top Autonomous systems based on number of transmitted bytes"))
sink()

# interesting destination ports
df_top_ip_x_port <- nfcapd_data %>%
    group_by(da, pr, sp) %>%
    summarise(sum_Mbyt = sum(byt)/1000000) %>%
    arrange(-sum_Mbyt) %>%
    head(20)
