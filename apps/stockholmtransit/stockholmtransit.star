load("render.star", "render")
load("http.star", "http")
load("time.star", "time")

RESROBOT_STOPS_URL = "https://api.resrobot.se/v2.1/departureBoard"
DEFAULT_STOP_ID = "740020101" # Slussen
DEFAULT_API_KEY = "80290625-d8bb-4983-8466-0c8cf4652fd0"
GEO_LOCATION = "Europe/Stockholm"
DEFAULT_TTL_SECONDS = 15
SL_OPERATOR_CODE = str(275)
PRODUCT_CLASS_CODE = str(4 + 16 + 32 + 64 + 128)

def main(config):

    stop_id = config.str("stop_id", DEFAULT_STOP_ID)
#    api_key = secret.decrypt("AV6+...") or config.get("api_key", DEFAULT_API_KEY)
    api_key = config.get("api_key", DEFAULT_API_KEY)
    ttl = config.get("ttl", DEFAULT_TTL_SECONDS)

    rep = http.get(
        RESROBOT_STOPS_URL,
        params = {
            "id": stop_id,
            "format": "json",
            "accessId": api_key,
            "operators": SL_OPERATOR_CODE,
            "products": PRODUCT_CLASS_CODE
        }
    )
    if rep.status_code != 200:
        fail("ResRobot request failed with status %d", rep.status_code)

    # Only display the three first departures of the stop
    dept = rep.json()["Departure"][0:4]

    # Trim stop name
    stop = dept[0]["stop"].split()[0]

    # Extract direction, line number and departure times    
    data = [
            dict(
                dir = d["direction"].split("(")[0],
                line = d["Product"][0]["displayNumber"],
                time = time.parse_time(
                    d["time"],
                    format = "15:04:05",
                    location = GEO_LOCATION
                )
            ) for d in dept ]

    now = time.now().in_location(GEO_LOCATION)

    rows = [
        render.Row(
            children=[
                render.Text(content=d["line"], color="#099"),
                render.Marquee(width=28, child=render.Text(content=d["dir"])),
                render.Text(content=format_duration(d["time"] - now), color="#834")
            ],
            main_align="space_evenly",
            expanded=True
        ) for d in data
    ]
    
    return render.Root(
        child = render.Column(
            children=[
                render.Text(stop),
                rows[0],
                rows[1],
                rows[2]
            ],
            main_align="start"
        )
    )

def format_duration(d):
    if d.hours > 1:
        return str(int(d.hours + 0.5)) + " h"
    elif d.minutes > 1:
        return str(int(d.minutes + 0.5)) + " min"
    else:
        return "now"