#!/bin/bash

sudo apt-get update
sudo apt-get install software-properties-common -y
sudo apt-add-repository ppa:deadsnakes/ppa -y
sudo apt-get update
sudo apt-get install python3.8 -y