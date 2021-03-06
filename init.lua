--  状态灯闪烁，tmr_id = 0
Lighton = true
gpio.mode(4, gpio.OUTPUT)
tmr.alarm(0, 1000, 1, function()
    Lighton = not Lighton
    if Lighton then
        gpio.write(4, gpio.HIGH)
    else
        gpio.write(4, gpio.LOW)
    end
end)

--  WiFi状态判断，tmr_id = 1
Previous_WiFiState = false
tmr.alarm(1, 1000, 1, function()
    status = wifi.sta.status()
if(status == 1) then
    tmr.start(0)
    if(Previous_WiFiState == true) then
        print("Lost WiFi connect,reconnecting...")
    else
        Previous_WiFiState = true
        print("Connecting WiFi...")
    end
end
if(status == 3) then
    tmr.start(0)
    print("No such AP found")
end
if(status == 5) then
    tmr.stop(0)
    gpio.write(4, gpio.HIGH)
    tmr.stop(1)
    tmr.start(3)
    print("Connect successfully, IPconfig:", wifi.sta.getip())
end
end)

--  WiFi连接成功后置异常监测，tmr_id = 2
tmr.alarm(2, 30000, 1, function()
if(wifi.sta.status() ~= 5) then
    tmr.start(1)
    tmr.stop(3)
end
end)

--  WiFi连接配置
SSID = ""
Password = ""
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, Password)
wifi.sta.autoconnect(1)

--  启动服务端
gpio.mode(0, gpio.OUTPUT)
srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
    conn:on("receive", function(client, request)
    print(request);
    local buf = "";
    local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP")
    if(method == nil) then
        _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
    end
    local _GET = {}
    if(vars ~= nil) then
        for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
            _GET[k] = v
        end
    end
    buf = buf.."<head><link rel=\"icon\" href=\"data:;base64,=\"></head><body><div style=\"border-radius: 25px; border: 5px solid #555555; padding: 20px; width: auto; height: auto;\"><h1 style=\"text-align:center;\">WiFi &#23567;&#28783;&#28783;&#25511;&#21046;</h1><h1 style=\"text-align:center;\">&#25511;&#21046; GPIO0 &#23567;&#28783;&#28783; & GPIO4 &#23567;&#28783;&#28783;</h1><h1><a href=\"?control=ON\"><button style=\"width:100%;background-color:#4CAF50;border:none;color:white;padding:15px 32px;text-align:center;text-decoration:none;display:inline-block;font-size:100px;border-radius:20px;box-shadow: 0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19);\"> ON </button></a></h1><h1><a href=\"?control=OFF\"><button style=\"width:100%;background-color:#f44336;border:none;color:white;padding:15px 32px;text-align:center;text-decoration:none;display:inline-block;font-size:100px;border-radius:20px;box-shadow: 0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19);\"> OFF </button></a></h1><h1><a href=\"?control=RELOAD\"><button style=\"width:100%;background-color:#008CBA;border:none;color:white;padding:15px 32px;text-align:center;text-decoration:none;display:inline-block;font-size:100px;border-radius:20px;box-shadow: 0 8px 16px 0 rgba(0,0,0,0.2), 0 6px 20px 0 rgba(0,0,0,0.19);\"> RELOAD </button></a></h1></div></body>"
    if(_GET.control == "ON") then
        gpio.write(4, gpio.LOW)
        gpio.write(0, gpio.HIGH)
    elseif(_GET.control == "OFF") then
        gpio.write(4, gpio.HIGH)
        gpio.write(0, gpio.LOW)
    elseif(_GET.control == "RELOAD") then
        node.restart()
    end
    client:send(buf)
    client:close()
    collectgarbage()
    end)
end)

--  连接酱菜创客，心跳包tmr_id = 3
key = ""
sid = "004"
nid = "000"
conncloud = net.createConnection(net.TCP, 0)
conncloud:connect(8266, "112.74.59.29")
conncloud:on("connection", function(conn, request)
    conn:send("mode=bind&apikey="..key.."&data={ck001000bind}")
    tmr.alarm(3, 60000, 1, function()
        conn:send("mode=up&apikey="..key.."&data={ck"..sid..nid.."life}")
    end)
end)
conncloud:on("receive", function(conn, request)
    print(request)
    if(string.sub(request, 10, 10) == "1") then
        gpio.write(4, gpio.LOW)
        gpio.write(0, gpio.HIGH)
    elseif(string.sub(request, 10, 10) == "0") then
        gpio.write(4, gpio.HIGH)
        gpio.write(0, gpio.LOW)
    end
end)
