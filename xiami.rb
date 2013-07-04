#encoding: utf-8
#!/usr/bin/ruby

require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'sinatra'

get '/' do
  "虾米歌曲编号: <form method ='post' action ='/xiami'><input name='xid' /> <br/> <input type=submit> </form>"
end

post "/xiami" do
	doc = Nokogiri::XML(open("http://www.xiami.com/widget/xml-single/uid/0/sid/#{params[:xid]}").read)
	node_values = doc.search('//trackList/track/location').map do |n|
	  mp3url(n.text)
	end  
end

def mp3url(str)
    num_loc = str.index('h')
    rows = str[0..num_loc].to_i
    strlen = str.size - num_loc
    cols = (strlen / rows).to_i
    right_rows = strlen % rows
    new_s = str[num_loc..-1]
    output = ''
    for i in 1..new_s.size
        x = i % rows
        y = i / rows
        p = 0
        if x <= right_rows then
            p = x * (cols + 1) + y
        else
            p = right_rows * (cols + 1) + (x - right_rows) * cols + y
        end
        output += new_s[p]	
    end
    "h#{CGI::unescape(output).gsub('^', '0')[0..-2]}"
end

