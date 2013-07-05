#encoding: utf-8
#!/usr/bin/ruby

%w[rubygems open-uri nokogiri sinatra cgi haml].each { |gem| require gem }
require "sinatra/reloader" if development?

get '/' do
  haml :index
end

post "/xiami" do
  param = "#{params[:xid]}".split('?').first.split('/').last
  doc = Nokogiri::XML(open("http://www.xiami.com/widget/xml-single/uid/0/sid/#{param}").read)
  doc.search('//trackList/track/location').map do |n|
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
    if x <= right_rows then
      p = x * (cols + 1) + y
    else
      p = right_rows * (cols + 1) + (x - right_rows) * cols + y
    end
    output << "#{new_s[p]}"
  end
  x = "h#{CGI::unescape(output).gsub('^', '0')}".split('.')[0...-1].join('.')
  "#{x}.mp3"
end

__END__
@@layout
!!! 5
%html
  %head
    %meta(charset="utf-8")
    %script{:type => 'text/javascript', :src => 'http://code.jquery.com/jquery-1.10.2.min.js'}
    %link(rel="stylesheet" href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css")
    %title xiami mp3 url
    :javascript
      $(function() {
        $("form#mp3form").submit(function(e){
          e.preventDefault();
          $.ajax({
            type: "POST",
            url: "/xiami",
            data: $('#mp3form').serialize(),
            success: function(data){
              $("#msg").html("歌曲 mp3 下载地址:  <font color=blue>" + data + "</font>")
            },
            error: function(){
              $("#msg").html("No MP3")
            }
          });
        });
      });
  %body
    %center
      %div(class="container")
        %div(class="hero-unit")
          %h4 虾米 mp3 获取器
          = yield

@@index
%form#mp3form(action="/xiami" method="POST")
  %div 输入虾米歌曲地址(例如: http://www.xiami.com/song/369173?spm=0.0.0.0.IAjRbk):
  %p
  %input#word(type="text" name="xid" class="span5 input-large")
  %p
  %input(type="submit" value="生成 MP3 下载地址" class="btn btn-primary btn-large")
#msg