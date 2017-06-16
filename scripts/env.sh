#!/bin/bash

export RUBYLIB="$HOME/omf-tools/:$HOME/.gem/ruby/1.9.1/gems/nokogiri-1.6.7.1/lib/:."
export PATH=$PATH:/$HOME/.gem/ruby/1.9.1/bin
export ENV=ORBIT
export MININETHOME="/home/mininet/mininetOmf"


python -m SimpleHTTPServer > http.log 2>&1 &
