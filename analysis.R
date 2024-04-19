library("tidyverse")
library("kableExtra")

nfcapd_data <- read_csv("aggregated_capture.csv",
                        col_names = c("sa", "da", "ts",  "td", "pr", "sp", "dp",
                                      "pkt", "ibyt", "obyt", "bps", "pps"),
                        col_types = cols(.default = col_character())) %>%
    mutate(ts = as_datetime(ts),
           td = hms(td),
           hour = hour(ts),
           day = day(ts),
           day = case_when(day == 2 ~ "2. April",
                           day == 3 ~ "3. April",
                           day == 4 ~ "4. April"),
           across(c(pkt, ibyt, obyt, bps, pps),
                  ~if_else(str_detect(., "M"),
                           true = str_replace(., "M", "") %>%
                               as.numeric %>%
                               `*`(1000000),
                           false = as.numeric(.)))) %>%
    drop_na(ibyt, pkt, da)

# overall load in Mbyte
print(sum((nfcapd_data$ibyt + nfcapd_data$obyt)/1000000000))
# number of flows
print(nrow(nfcapd_data))
# very low because of low byte entries
plot_bytes <- ggplot(data = group_by(nfcapd_data, hour, day) %>%
                         summarise(bph = sum(ibyt)/1000000),
                     mapping = aes(x = hour, y = bph)) +
    geom_col() +
    scale_x_continuous(breaks = seq(8,22, 2)) +
    facet_wrap(~day) +
    labs(y = "Transmitted MB Total", x = "Hour")

plot_packets <- ggplot(data = nfcapd_data,
                       mapping = aes(x = hour, y = sum(pkt))) +
    geom_col() +
    facet_wrap(~day) +
    labs(y = "Transmitted Packets Total", x = "Hour")

ggsave(plot = plot_bytes,
       filename = "plot_bytes.pdf",
       width = 12,
       height = 8,
       units = "cm")

ggsave(plot = plot_packets,
       filename = "plot_packets.pdf",
       width = 12,
       height = 8,
       units = "cm")

# With which IP Icommunicate with the most?

df_top_hosts <- nfcapd_data %>%
    group_by(da) %>%
    summarise(sum_Mbyt = round(sum(ibyt)/1000000)) %>%
    slice_max(n = 10, order_by = sum_Mbyt) %>%
    mutate(domain= map_chr(da, ~ {
        ns_response <- system(paste("nslookup ", .x), intern=TRUE)
        tname <- ns_response[str_detect(ns_response, "\tname =")]
        if (length(tname) == 0) {
            return("None")
        } else {
            return(str_split(tname, "= ")[[1]][2])
        }
    }))

# save latex table
sink("top_hosts.tex")
kable(df_top_hosts,
      format = "latex",
      col.names = c("Dest. IP-Address", "MByte Total", "Domain"),
      caption = "Top 10 IP-Addresses based on transmitted bytes")
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
    summarise(sum_Mbyte = round(sum(ibyt)/1000000, 2)) %>%
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
    summarise(sum_Mbyt = round(sum(ibyt)/1000000, 2)) %>%
    arrange(-sum_Mbyt) %>%
    head(15)

sink("top_ip_x_port.tex")
kable(df_top_ip_x_port,
      format = "latex",
      col.names = c("IP-Address", "Protocol", "Source Port", "MByte Total"),
      caption = "Top 15 IP-Addresses based on transmitted bytes by protocol and source port")
sink()
