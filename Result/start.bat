@echo off
cd src
erlc server.erl

echo Compiled

cd ..
erl -noshell -pa ./src -s server -s inets -config my_server
