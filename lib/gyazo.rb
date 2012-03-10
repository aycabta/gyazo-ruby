# -*- coding: utf-8 -*-
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'net/http'

class Gyazo
  VERSION = '0.0.1'

  def initialize(app = '/Applications/Gyazo.app')
    @user = IO.popen("whoami", "r+").gets.chomp
    @program = app
    @idfile = "/Users/#{@user}/Library/Gyazo/id"
    @old_idfile = File.dirname(@program) + "/gyazo.app/Contents/Resources/id"
    @id = ''
    if File.exist?(@idfile) then
      @id = File.read(@idfile).chomp
    elsif File.exist?(@old_idfile) then
      @id = File.read(@old_idfile).chomp
    end
  end

  def upload(imagefile)
    tmpfile = "/tmp/image_upload#{$$}.png"
    if imagefile && File.exist?(imagefile) then
      system "sips -s format png \"#{imagefile}\" --out \"#{tmpfile}\""
    end
    imagedata = File.read(tmpfile)
    File.delete(tmpfile)

    boundary = '----BOUNDARYBOUNDARY----'
    @host = 'gyazo.com'
    @cgi = '/upload.cgi'
    @ua   = 'Gyazo/1.0'
    data = <<EOF
--#{boundary}\r
content-disposition: form-data; name="id"\r
\r
#{@id}\r
--#{boundary}\r
content-disposition: form-data; name="imagedata"; filename="gyazo.com"\r
\r
#{imagedata}\r
--#{boundary}--\r
EOF
    header ={
      'Content-Length' => data.length.to_s,
      'Content-type' => "multipart/form-data; boundary=#{boundary}",
      'User-Agent' => @ua
    }
    res = Net::HTTP.start(@host,80){|http|
      http.post(@cgi,data,header)
    }

    # @url = res.response.to_ary[1]
    @url = res.read_body

    # system "echo #{@url} | pbcopy"
    # system "open #{url}"

    # save id
    # newid = res.response['X-Gyazo-Id']
    newid = res['X-Gyazo-Id']
    if newid and newid != "" then
      if !File.exist?(File.dirname(@idfile)) then
        Dir.mkdir(File.dirname(@idfile))
      end
      if File.exist?(@idfile) then
        File.rename(@idfile, @idfile+Time.new.strftime("_%Y%m%d%H%M%S.bak"))
      end
      File.open(@idfile,"w").print(newid)
      if File.exist?(@old_idfile) then
        File.delete(@old_idfile)
      end
    end
    @url
  end

end