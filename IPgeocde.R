# Geocode CRAN packages by maintainer location, based on their email domain IP address
# (instead of aggregating over country polygons.)
# ce - 2010-03-08

library(httr)
library(ggplot2)
library(readr)

# Downloading metadata for ~8000 packages takes a while. 
# Easier to use the table I extracted here:
CRANmaint <- read_csv(url("https://raw.githubusercontent.com/cengel/r_IPgeocode/master/CRANpkgMaintainers.csv"))

# get the last n elements of a domain name d, assumed to be a string separated by dots
domain_getlastN <- function (d, n){ 
  s <- strsplit(d, "\\.")[[1]]  
  l <- length(s)
  # need to thow error if l >= n
  e <- s[l]
  if (n > 1) {
    for (i in seq_len(n-1)){
      e <- paste0(s[l-i], ".", e)
    }
  }
  return(e)
}

# take a domain name d and try different combos to find IP
# note, this is completely based on trial and error...
getDomainIP <- function (d){
  h <- domain_getlastN(d, 2) # get last 2
  ip <- nsl(h)
  if(is.null(ip)) { 
    ip <-  nsl(paste0("www.", h)) # try to prepend www

    if(is.null(ip)) {
      h <- domain_getlastN(d, 3) # get last 3
      ip <-  nsl(h) 
    }
    if(is.null(ip)) {
      ip <-  nsl(paste0("www.", h)) # try to prepend www
    }
    if(is.null(ip)) {
      h <- domain_getlastN(d, 4) # get last 4
      ip <-  nsl(h) 
    }
    if(is.null(ip)) {
      ip <-  nsl(paste0("www.", h)) # try to prepend www
    }          
  } else if (strsplit(ip, "\\.")[[1]][1] == "10") {
      ip <- nsl(paste0("www.", h))   #  if ip begins with 10. prepend www
  }
  return(ip)
}

# strip out the domains from the email
# helper to get last element in a split string
strsplit_getlast <- function (x, p){ # x - string, p - pattern
  s <- strsplit(x, p)[[1]]  
  l <- length(s)
  return (s[l])
}
domain.names <- do.call("rbind", sapply(CRANmaint$maintainer, function(x) tolower(strsplit_getlast(x,"[@>]")), simplify = F))

# get IPs, takes a while ..
ips <- do.call("rbind", sapply(domain.names, function(x) getDomainIP(x), simplify = F))

# takes an IP address and returns lat/lon
# using my freegeoip localhost server for this
# -- I set up freegeoip locally in about *2* minutes and it works terriffic.
# -- download (Mac) binary: https://github.com/fiorix/freegeoip/releases
# -- go to terminal window, change into directory where it is unzipped 
# -- launch with: ./freegeoip
# -- test in another terminal window with: curl localhost:8080/json/1.2.3.4
# now throw your IPs at it!
geocodeIP <- function(x){
  require(httr)
  uri <- paste0("http://localhost:8080/json/", x)
  res <- content(GET(uri))
  return (data.frame(lon=res$longitude, lat=res$latitude)) # order is x, y
}

# get Lat/Lon
ips.ll <- do.call("rbind", sapply(ips, function(x) geocodeIP(x), simplify = F))

# to plot aggregate over unique lat/lon so we have the counts of hosts per location
ll.cnt <- aggregate(ips.ll, list(lon = ips.ll$lon, lat = ips.ll$lat), FUN=length)[,1:3]
names(ll.cnt)[3] <- "hosts"
library(maps)
wrld <- map_data("world")
ggplot() + 
  geom_polygon( data=wrld, aes(x=long, y=lat, group = group), colour="grey70", size=.3, fill="white") +
  geom_point(data=ll.cnt, aes(lon, lat, size=log(hosts)), color="lime green", alpha=.2) +
  theme_bw() +
  theme(plot.background = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank()) +
  coord_equal()

