DEFAULT_WHO = "world"

def main(config):
    who = config.get("who", DEFAULT_WHO)
    print("Hello, %s" % who)
