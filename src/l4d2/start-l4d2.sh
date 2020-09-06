#!/usr/bin/env bash
steamcmd +runscript /opt/l4d2/l4d2-steamcmd-script;
wget https://raw.githubusercontent.com/mcpdude/l4d2-server/master/src/l4d2/addonconfig.cfg;
mv addonconfig.cfg /opt/l4d2/game/left4dead2/cfg;
/opt/l4d2/game/srcds_run -ip 0.0.0.0 -port 27015 -secure +map c5m1_waterfront;
