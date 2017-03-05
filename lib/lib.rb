require 'net/https'
require 'json'

module Lib
  class << self
    def [](name)
      LibGen.proxy_method_missing(name)
    end
  
    def method_missing(name)
      LibGen.proxy_method_missing(name)
    end
  end
  
  class LibGen

    HOST = 'f.stdlib.com'
    PORT = 443
    PATH = '/'

    attr_reader :host, :port, :path

    def self.proxy_method_missing(name)
      self.new[name]
    end

    def initialize(host = HOST, port = PORT, path = PATH, names=[])
      @host = host
      @port = port
      @path = path
      @names = names
    end

    def to_s
      @names.join('.')
    end

    def append_version(names, str)
      if /^@[A-Z0-9\-\.]+$/i !~ str then
        raise StandardError, "#{names.join('.')} invalid version: #{str}"
      end

      names + [str]
    end

    def append_path(names, str)
      if /^[A-Z0-9\-]+$/i !~ str then
        if str.include? '@' then
          raise StandardError, "#{names.join('.')} invalid name: #{str}, please specify versions and environments with [@version]"
        end

        raise StandardError, "#{names.join('.')} invalid name: #{str}"
      end
      names + [str]
    end

    def append_lib_path(names, str)
      default_version = '@release'
      if names.empty? && str.empty? then
        ['']
      elsif names.empty? && str.include?('.') then
        arr = if version_match = str.match(/^[^\.]+?\.[^\.]*?(\[@[^\[\]]*?\])(\.|$)/)
          version = version_match[1]
          version = version.gsub(/^\[?(.*?)\]?$/, '\1')
          str = str.gsub version_match[1], ''
          arr = str.split('.')
          arr[0...2] + [version] + (arr[2..-1] || [])
        else
          if str == '.' then [''] else str.split '.' end
        end
        while arr.length > 0 do
          names = append_lib_path(names, arr.shift)
        end
        names
      elsif names.length === 2 && !names.first.empty? then
        if str.start_with?("@") then
          append_version(names, str)
        else
          append_path(append_version(names, default_version), str)
        end
      else
        append_path(names, str)
      end
    end

    def [](name)
      method_missing(name)
    end

    def method_missing(name)
      LibGen.new(host, port, path, append_lib_path(@names, name.to_s))
    end

    def make_http_call(args, kwargs, name)
      body = JSON.generate({args: args, kwargs: kwargs})
      https = Net::HTTP.new(host, port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new "#{path}#{name}"
      req.add_field 'Content-Type', 'application/json'
      req.body = body
      https.request req
    end

    def exec!(*args)
      names = @names
      account, function, *rest = names
      path = [account,function].join("/") + rest.join("/")
      kwargs = if args[-1].kind_of? Hash then args.pop else {} end
      is_local = names.first.empty?

      begin
        args.each do |v|
          if ![nil, true, false, String, Numeric].any? {|t| v === t } then
              raise ArgumentError, "Lib.#{names.join('.')}: All arguments must be Boolean, Number, String or nil", caller[2..-1]
          end
        end

        if is_local then
          raise StandardError, "StdLib local execution currently unavailable in Ruby", caller
        end


	http_response = make_http_call(args, kwargs, path)

        headers = {}
        status = http_response.code.to_i
        http_response.each_header { |header, value| headers[header.downcase] = value }
        content_type = headers['content-type']
        response = http_response.body

        response = if content_type === 'application/json' then
          begin
           ('{['.include? http_response.body.to_s[0]) ? JSON.parse(http_response.body.to_s) : JSON.parse("[#{http_response.body_.to_s}]")[0]
          rescue
           nil
          end
        elsif content_type =~ /^text\/.*$/i then
          http_response.body.to_s
        end

        if status / 100 != 2 then
          raise StandardError, "#{response}", caller
        end

      rescue Exception => e

        if block_given? then
          yield e, nil
          return
        else
          raise e
        end

      end

      if block_given? then
        yield nil, response
        return
      else
        return response
      end

    end

    private :append_version
    private :append_path
    private :append_lib_path

  end

  private_constant :LibGen

end
