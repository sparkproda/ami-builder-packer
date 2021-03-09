#!/bin/bash

apt-get update
apt-get install software-properties-common -y
apt-add-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install python3.8 -y