--############
--# Settings #
--############

--- MQTT ---
mqtt_broker_ip = "192.168.100.7"     
mqtt_broker_port = 1883
mqtt_username = ""
mqtt_password = ""
mqtt_client_id = ""

--- WIFI ---
wifi_SSID = "viksun"
wifi_password = "password"
wifi_signal_mode = wifi.PHYMODE_N
client_ip=""
client_netmask=""
client_gateway=""

--- DOMOTICZ ---
temp_hum_idx = 3
co2_idx=4
refresh_period = 30000

--################
--# END settings #
--################

-- Setup MQTT client and events
m = mqtt.Client(client_id, 120, username, password)
temperature = 0
humidity = 0

-- Connect to the wifi network
wifi.setmode(wifi.STATION) 
wifi.setphymode(wifi_signal_mode)
wifi.sta.config(wifi_SSID, wifi_password) 
wifi.sta.connect()
if client_ip ~= "" then
    wifi.sta.setip({ip=client_ip,netmask=client_netmask,gateway=client_gateway})
end

mhz19 = require("mhz19")

-- DHT22 sensor logic
function get_sensor_Data() 
    dht=require("dht")
    status,temperature,humidity = dht.read(4)
        if( status == dht.OK ) then
            print("Temperature: "..temperature.."C")
            print("Humidity: "..humidity.."%")
        elseif( status == dht.ERROR_CHECKSUM ) then          
            print( "DHT Checksum error" )
            temperature="null"
            humidity="null"
        elseif( status == dht.ERROR_TIMEOUT ) then
            print( "DHT Time out" )
            temperature="null"
            humidity="null"
        end
    -- Release module
    dht=nil
    package.loaded["dht"]=nil
end

function loop() 
    if wifi.sta.status() == 5 then
        -- Stop the loop
        tmr.stop(0)
        m:connect( mqtt_broker_ip , mqtt_broker_port, 0, function(conn)
            print("Connected to MQTT")
            pub()
            tmr.alarm(0, refresh_period, 1, function() pub() end)
        end 
        )
    else
        print("Connecting...")
    end
end

function pub()
    get_sensor_Data()
    m:publish("domoticz/in", "{\"idx\": "..temp_hum_idx..", \"svalue\": \""..temperature..";"..humidity..";0\"}", 0, 0, function(conn)           
        mhz19:measure(function(mhz)
            print("CO2: "..mhz)
            m:publish("domoticz/in", "{\"idx\": "..co2_idx..", \"nvalue\": "..mhz.."}", 0, 0, function(conn)        
            end)
        end)
    end)
end
        
tmr.alarm(0, 1000, 1, function() loop() end)

