#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

#
# Simple gopher example
#

require 'gopher2000'

set :host, '0.0.0.0'
set :port, 7070

route '/figlet' do
  render :figlet
end

#
# special text output rendering
#
text :figlet do
  @text = "Hello!"

  # nicely wrapped text
  figlet @text

  # spacing
  br(2)
end
