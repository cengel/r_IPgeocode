# r_IPgeocode

Geocodes emails based on the email domain IP address. This example uses emails of CRAN package maintainers.

Ot geocode the IP adresses I use [freegeoip](http://freegeoip.net/) which I set up locally in less than 2 minutes:

1. [Download](https://github.com/fiorix/freegeoip/releases) binary
2. Go to terminal window, change into directory where it is unzipped
3. Launch with: ./freegeoip`
4. Test in another terminal window with: `curl localhost:8080/json/1.2.3.4`
5. ..now throw your IPs at it!

A map of all the geocoded hosts:

![host map](https://raw.githubusercontent.com/cengel/r_IPgeocode/master/map.png)
