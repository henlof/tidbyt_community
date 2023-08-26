load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("schema.star", "schema")
load("humanize.star", "humanize")

RESROBOT_STOPS_URL = "https://api.resrobot.se/v2.1/departureBoard"
DEFAULT_STOP_ID = "740020101" # Slussen
DEFAULT_API_KEY = "80290625-d8bb-4983-8466-0c8cf4652fd0"
GEO_LOCATION = "Europe/Stockholm"
DEFAULT_TTL_SECONDS = 15
SL_OPERATOR_CODE = str(275)
PRODUCT_CLASS_CODE = str(4 + 16 + 32 + 64 + 128)
FONT = "tom-thumb"

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
                timestamp = create_timestamp(d["date"], d["time"], GEO_LOCATION)
            ) for d in dept ]

    now = time.now().in_location(GEO_LOCATION)

    print(data[0]["timestamp"])
    print(now)

    rows = [
        render.Row(
            children=[
                render.Text(content=d["line"], color="#099", font = FONT),
                render.Marquee(width=28, child=render.Text(content=d["dir"], font = FONT)),
                render.Text(content=humanize.relative_time(d["timestamp"], now), color="#834", font = FONT)
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
                rows[2],
                rows[3]
            ],
            main_align="start"
        )
    )

def create_timestamp(d, t, loc):
    yy, mm, dd = d.split("-")
    hh, m, s = t.split(":")
    n = 0
    return time.time(
        year = int(yy), month = int(mm), day = int(dd), 
        hour = int(hh), minute = int(m), second = int(s),
        nanosecond = n, location = loc)

def get_time(d, t):
    return time.parse_time(
        d + "T" + t,
        format = "2023-10-02T10:18:00",
        location = GEO_LOCATION
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "stop_id",
                name = "ResRobot stop ID",
                desc = "ID of the stop you wish to monitor",
                icon = "user",
            )
        ],
    )