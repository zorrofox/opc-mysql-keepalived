#!/bin/bash
pkill keepalived
opc compute routes update ${mysql_vip_route} 192.168.2.88/32 ${mysql_vnset}