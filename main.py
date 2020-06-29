import powertop
from influxdb import InfluxDBClient
from time import sleep
import json

client = InfluxDBClient(database="power_consumption")
client_process = InfluxDBClient()
client_process.create_database("process_consumption")
client_process.switch_database("process_consumption")

retry = True
while retry:
    try:
        res = client.query("SELECT power FROM power_consumption GROUP BY * ORDER BY DESC LIMIT 1")
        total_power = list(res.get_points(measurement="power_consumption"))[0]['power']
        measures = powertop.Powertop().get_measures(time=1)["Top 10 Power Consumers"]
        for measure in measures:
            usage = total_power * (float(measure['Usage'][:-1]) / 100)
            client_process.write_points([{
            "measurement": "power_consumption",
            "tags": {
                "description": measure["Description"],
                "category": measure["Category"]
            },
            "fields": {
                "usage": usage
            }
            }])
        sleep(1)
    except Exception as e:
        print(f"error {e}")
