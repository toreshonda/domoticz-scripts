--[[
name : synology.lua
auteur : papoo
creation : 24/08/2018
mise à  jour : 03/09/2018

https://pon.fr/dzvents-supervision-dun-nas-synology-avec-snmp/
https://github.com/papo-o/domoticz_scripts/blob/master/dzVents/scripts/Synology.lua
https://easydomoticz.com/forum/viewtopic.php?f=17&t=7022
http://www.domoticz.com/forum/viewtopic.php?f=59&t=24618

For this script to work you need to enable SNMP on your synology NAS and install SNMP on your Raspberry Pi

Enable SNMP on your synology NAS
 
Go toMain Menu>Control Panel >SNMP to enable SNMP service, which allows users to monitor
Synology DiskStation network flow with the network management software.

You can use V1/V2
And set a password (Community)

Install SNMP on Raspberry Pi
Log in to you Raspberry Pi and issue:

sudo apt-get install snmpd
sudo apt-get install snmp

Reboot your Pi:
sudo reboot

Check if SNMP is up and running, issue:
snmpget -v 2c -c PASSWORD -O qv NASIPADDRESS 1.3.6.1.4.1.6574.1.5.1.0

Replace PASSWORD with the Community name you entered while setting up your NAS
Replace NASIPADDRESS with the ip address of your NAS
You should get something like this:
"DS218+" which corresponds to your Synology Model

test 
snmpget -v 2c -c PASSWORD -O qv NASIPADDRESS 1.3.6.1.2.1.25.2.3.1.5.31
snmpget -v 2c -c PASSWORD -O qv NASIPADDRESS 1.3.6.1.2.1.25.2.3.1.5.38
snmpget -v 2c -c PASSWORD -O qv NASIPADDRESS 1.3.6.1.2.1.25.2.3.1.5.41
then modify     OID_HDUnit, OID_HDTotal, OID_HDUsed variables (.38 on DSM 5.1, .41 on DSM 6.0+ or .31 on my new DS218)

if you have à DS2XX model, uncomment     -- local OID_HDtemp2='1.3.6.1.4.1.6574.2.1.1.6.1'  to show the hdd2 temperature
Then create:
1 device Switch
1 temperature device
3 percent devices
1 meter device   
--]]
--------------------------------------------
-------------Fonctions----------------------
-------------------------------------------- 
function format(str)
   if (str) then
      str = string.gsub (str, " Bytes", "")
      str = string.gsub (str, " kB", "")

   end
   return str   
end

-------------------------------------------
-------------Fin Fonctions-----------------
-------------------------------------------

    local NasIp = "192.168.100.250"                             -- NAS IP Address
    local CommunityPassword = "private"                         -- SNMP Password
    local NAS = "Synology"                                      -- NAS Switch
    local NAS_HD1_TEMP = "Synology Temp"                        -- NAS HD1 Temp => 
    local NAS_CPU = "Synology Utilisation CPU"                  -- NAS CPU 
    local NAS_MEM = "Synology Utilisation RAM"                  -- NAS MEM 
    local NAS_HD_SPACE_PERC = "Synology Occupation Disque"      -- NAS HD Space  in %
    local NAS_HD_SPACE = "Synology Espace Disponible"           -- NAS HD Space  in Go
    local NAS_HD2_TEMP = ""                                     -- NAS HD2 Temp 
    local OID_HDtemp1 = '1.3.6.1.4.1.6574.2.1.1.6.0'            -- Temperature HD1
    local OID_HDUnit = '1.3.6.1.2.1.25.2.3.1.4.41'              -- OID HD Unit Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+ or .31 on my new DS218
    local OID_HDTotal = '1.3.6.1.2.1.25.2.3.1.5.41'             -- OID Total space volume in Go Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+ or .31 on my new DS218
    local OID_HDUsed = '1.3.6.1.2.1.25.2.3.1.6.41'              -- OID Space used volume in Go Change OID to .38 on DSM 5.1 or .41 on DSM 6.0+or .31 on my new DS218
    local OID_CpuUser = '1.3.6.1.4.1.2021.11.9.0'               -- OID CPU user
    local OID_CpuSystem = '1.3.6.1.4.1.2021.11.10.0'            -- OID CPU System
    local OID_MemAvailable = '1.3.6.1.4.1.2021.4.13.0'          -- OID Free Memory Available
    -- local OID_HDtemp2='1.3.6.1.4.1.6574.2.1.1.6.1'           -- OID Temperature HD2    
return {
    active = true,
    on = {
    timer = {'every minute'}
    },    
   -- on = { devices = { "your trigger device" }},
        
  logging =   { -- level    =   domoticz.LOG_INFO,                                             -- Seulement un niveau peut être actif; commenter les autres
                level    =   domoticz.LOG_ERROR,                                            -- Only one level can be active; comment others
                -- level    =   domoticz.LOG_DEBUG,
                -- level    =   domoticz.LOG_MODULE_EXEC_INFO,
                marker    =   "Synology Monitor v1.04 "      },
    
    execute = function(dz)
        local i = 0
        local results = {}
        local command = 'snmpget -v 2c -c '..CommunityPassword..' -O qv '..NasIp..' '..OID_HDtemp1..' '..OID_HDUnit..' '..OID_HDTotal..' '..OID_HDUsed..' '..OID_CpuUser..' '..OID_CpuSystem..' '..OID_MemAvailable --..' '..OID_HDtemp2
        local handle = assert(io.popen(command))
        for line in handle:lines() do
        --for i, line in pairs(handle) do
            --dz.log(format(line),dz.LOG_DEBUG)
            results[i] =  format(line)
            i = i + 1
        end
        handle:close()
        if results[0] then
            dz.log("HDTemp1 : "..results[0],dz.LOG_DEBUG)
            dz.devices(NAS_HD1_TEMP).update(0,results[0])
            end
        if results[1] then dz.log("HDUnit : "..results[1],dz.LOG_DEBUG) end        
        if results[2] then dz.log("HDTotal : "..results[2],dz.LOG_DEBUG) end        
        if results[3] then dz.log("HDUsed : "..results[3],dz.LOG_DEBUG) end
        if results[4] then dz.log("CpuUser : "..results[4],dz.LOG_DEBUG) end      
        if results[5] then dz.log("CpuSystem : "..results[5],dz.LOG_DEBUG) end  
        if results[6] then dz.log("MemAvailable : "..results[6],dz.LOG_DEBUG) end
        if results[7] then
            dz.log("HDTemp2 : "..results[0],dz.LOG_DEBUG)
            if NAS_HD2_TEMP then dz.devices(NAS_HD2_TEMP).update(0,results[0]) end
            end        
        local HDFree = dz.utils.round(((results[2] - results[3]) *  results[1] / 1024 / 1024 / 1024), 0)
        if HDFree then 
            dz.log("HDFree : "..HDFree,dz.LOG_DEBUG) 
            dz.devices(NAS_HD_SPACE).update(0,HDFree)
            end 
        local HDFreePerc = dz.utils.round(((results[3] * 100) / results[2]), 0)
        if HDFreePerc then 
            dz.log("HDFreePercent : "..HDFreePerc,dz.LOG_DEBUG)
            dz.devices(NAS_HD_SPACE_PERC).update(0,HDFreePerc)
            end
        local CpuUsed = (results[4] + results[5])
        if CpuUsed then 
            dz.log("CpuUsed : "..CpuUsed,dz.LOG_DEBUG)
            dz.devices(NAS_CPU).update(0,CpuUsed)
            end
        local MemUsedPerc = dz.utils.round((((results[6] / 1024) *100 / 1024)), 0)
        if MemUsedPerc then 
            dz.log("MemUsedPercent : "..MemUsedPerc,dz.LOG_DEBUG)
            dz.devices(NAS_MEM).update(0,MemUsedPerc)
            end
        if results[0] and results[5] and results[6] then
                dz.log("Requete SNMP correcte ",dz.LOG_DEBUG)
                dz.devices(NAS).switchOn().checkFirst()
            else
                dz.log("Requete SNMP incorrecte ",dz.LOG_DEBUG)
                dz.devices(NAS).switchOff().checkFirst()
            end
            
    end
}
