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

post "/album" do
  afrom = "#{params[:afrom]}".split('?').first.split('/').last
  ato = "#{params[:ato]}".split('?').first.split('/').last
  output = ''
  threads = []
  (afrom.to_i..ato.to_i).each do |o|
    threads << Thread.new {
      doc = Nokogiri::XML(open("http://www.xiami.com/widget/xml-single/uid/0/sid/#{o}").read)
      doc.search('//trackList/track/location').map do |n|
        Thread.current[:output] = mp3url(n.text) + "<p/>"
      end
    }
  end
  threads.each do |t|
    t.join
    output << t[:output]
  end
  output
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
  "<a href='#{x}.mp3'>#{x}.mp3</a>"
end

__END__
@@layout
!!! 5
%html
  %head
    %meta(charset="utf-8")
    %link(rel="stylesheet" href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.2/css/bootstrap-combined.min.css")
    %script{:type => 'text/javascript', :src => 'http://code.jquery.com/jquery-1.10.2.min.js'}
    %script{:type => 'text/javascript', :src => 'http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js'}
    %title xiami mp3 url
    :javascript
      $(function() {
        $("form#mp3form").submit(function(e){
          $("#msg").html("<font color=red>mp3 下载地址生成中...</font>");
          e.preventDefault();
          $.ajax({
            type: "POST",
            url: "/xiami",
            data: $('#mp3form').serialize(),
            success: function(data){
              $("#msg").css("background-color","#DDDDDD");
              $("#msg").html("歌曲 mp3 下载地址: <p/> <font color=blue>" + data + "</font>")
            },
            error: function(){
              $("#msg").html("No MP3")
            }
          });
        });

        $("form#albumform").submit(function(e){
          $("#msg").html("<font color=red>mp3 下载地址生成中...</font>");
          e.preventDefault();
          $.ajax({
            type: "POST",
            url: "/album",
            data: $('#albumform').serialize(),
            success: function(data){
              $("#msg").css("background-color","#DDDDDD");
              $("#msg").html("专辑 mp3 下载地址: <p/> <font color=blue>" + data + "</font>")
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
          = yield

@@index

%div.tabbable
  %ul(class="nav nav-tabs")
    %li(class="active")
      %a(href="#tab1" data-toggle="tab") 虾米单曲 mp3
    %li
      %a(href="#tab2" data-toggle="tab") 虾米专辑 mp3
  %div.tab-content
    %div(class="tab-pane active" id="tab1")
      %form#mp3form(action="/xiami" method="POST")
        %div 输入虾米歌曲地址(例如: http://www.xiami.com/song/369173 , 注: 必须是这样的虾米歌曲网址):
        %p
        %input#word(type="text" name="xid" class="span5 input-large")
        %p
        %input(type="submit" value="生成 MP3 下载地址" class="btn btn-primary btn-large")
    %div(class="tab-pane" id="tab2")
      %form#albumform(action="/album" method="POST")
        %p
        %div 例如: 专辑网址:  <如诗般 宁静> http://www.xiami.com/album/240537
        %p
        %div 输入专辑第一首歌曲地址(例如: http://www.xiami.com/song/2783254?spm=a1z1s.3057849.0.0.8mNBuR , 注: 必须是类似网址):
        %p
        %input#word(type="text" name="afrom" class="span5 input-large")
        %p
        %div 输入专辑最后一首歌曲地址(例如: http://www.xiami.com/song/2783264?spm=a1z1s.3057849.0.0.8mNBuR , 注: 必须是类似网址):
        %p
        %input#word(type="text" name="ato" class="span5 input-large")
        %p
        %input(type="submit" value="生成专辑 MP3 下载地址" class="btn btn-primary btn-large")
        %p
        %div{ :style => "color:#F00"} 注意:
        %strong 超过10首歌曲的专辑, 最好分开生成, 比如一张专辑30首歌曲, 可以选择 1-10, 11-20, 21-30 来生成 mp3 链接, 以免服务器因多线程问题无法生成mp3地址
%p
%hr
%p
#msg