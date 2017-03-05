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

    attr_reader :host, :port, :path, :names

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
    def [](name)
      method_missing(name)
    end

    def method_missing(name)
      LibGen.new(host, port, path, append_lib_path(@names, name.to_s))
    end

    def exec!(*args)
      names = @names
      account, function, *rest = names
      path = [account,function].join("/") + rest.join("/")
      kwargs = if args.last.kind_of? Hash then args.pop else {} end

      pre_request_validations!(args)

      http_response = make_http_call(args, kwargs, path)
      status = http_response.code.to_i

      response = parse_response(http_response)

      if status / 100 != 2 then
        raise StandardError, "#{response}"
      end

      if block_given? then
        yield response
        return
      else
        response
      end
    end

    private

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
  
      def validate_args!(args)
        args.each do |v|
          if ![nil, true, false, String, Numeric].any? {|t| v === t } then
              raise ArgumentError, "Lib.#{names.join('.')}: All arguments must be Boolean, Number, String or nil"
          end
        end
      end
  
      def validate_non_local_call!
        if @names.first.empty? then
          raise StandardError, "StdLib local execution currently unavailable in Ruby"
        end
      end
  
      def pre_request_validations!(args)
        validate_args!(args)
        validate_non_local_call!
      end

      def parse_response(http_response)
        if http_response['content-type'] == 'application/json' then
         ('{['.include? http_response.body.to_s[0]) ? JSON.parse(http_response.body.to_s) : JSON.parse("[#{http_response.body_.to_s}]")[0]
        elsif http_response['content-type'] =~ /^text\/.*$/i then
          http_response.body.to_s
        end
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
        elsif names.length == 2 && !names.first.empty? then
          if str.start_with?("@") then
            append_version(names, str)
          else
            append_path(append_version(names, default_version), str)
          end
        else
          append_path(names, str)
        end
      end

    private :host, :port, :path, :names

  end

  private_constant :LibGen

end
