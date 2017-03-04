require 'net/https'
require 'json'

module Lib
  class << self
    def [](name)
      proxy_to_generator(name)
    end
  
    def method_missing(name)
      proxy_to_generator(name)
    end
  
    def proxy_to_generator(name)
      LibGen.new[name]
    end
  end
  
  class LibGen

    HOST = 'f.stdlib.com'
    PORT = 443
    PATH = '/'

    attr_reader :host, :port, :path

    def initialize(host = HOST, port = PORT, path = PATH, names=[])
      @host = host
      @port = port
      @path = path
      @names = names
    end

    def to_s()
      @names.join('.')
    end

    def __append_version__(names, str)
      if /^@[A-Z0-9\-\.]+$/i !~ str then
        raise StandardError, "#{names.join('.')} invalid version: #{str}"
      end

      names + [str]
    end

    def __append_path__(names, str)
      if /^[A-Z0-9\-]+$/i !~ str then
        if str.include? '@' then
          raise StandardError, "#{names.join('.')} invalid name: #{str}, please specify versions and environments with [@version]"
        end

        raise StandardError, "#{names.join('.')} invalid name: #{str}"
      end
      names + [str]
    end

    def __append_lib_path__(names, str)
      names = if names.length then names + [] else [] end
      default_version = '@release'

      if names.length === 0 && str === '' then

        return names + [str]

      elsif names.length === 0 && (str.include? '.') then

        arr = if versionMatch = str.match(/^[^\.]+?\.[^\.]*?(\[@[^\[\]]*?\])(\.|$)/)
          version = versionMatch[1]
          version = version.gsub(/^\[?(.*?)\]?$/, '\1')
          str = str.gsub versionMatch[1], ''
          arr = str.split '.'
          arr[0...2] + [version] + (arr[2..-1] || [])
        else
          if str == '.' then [''] else str.split '.' end
        end

        while arr.length > 0 do
          names = __append_lib_path__(names, arr.shift)
        end

        return names

      elsif names.length === 2 && names[0] != '' then

        if str[0] === '@' then

          return __append_version__(names, str)

        else

          return __append_path__(__append_version__(names, default_version), str)

        end

      else

        return __append_path__(names, str)

      end

    end

    def [](name)
      self.method_missing(name)
    end

    def method_missing(name)
      LibGen.new(host, port, path, __append_lib_path__(@names, name.to_s))
    end

    def make_http_call(args, kwargs, name)
      body = JSON.generate({args: args, kwargs: kwargs})
      https = Net::HTTP.new(host, port)
      https.use_ssl = true
      https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new "#{@path}#{name}"
      req.add_field 'Content-Type', 'application/json'
      req.body = body
      https.request req
    end

    def exec!(*args)
      names = @names
      name = names[0...2].join('/') + (if names[2..-1] then names[2..-1].join('/') else '' end)
      kwargs = if args[-1].is_a? ::Hash then args.pop else {} end
      is_local = names[0].empty?
      response = nil

      begin

        args.each do |v|
          if ![nil, true, false, String, Numeric].any? {|t| v === t } then
              raise ArgumentError, "Lib.#{names.join('.')}: All arguments must be Boolean, Number, String or nil", caller[2..-1]
          end
        end

        if is_local then
          raise StandardError, "StdLib local execution currently unavailable in Ruby", caller
        end


	http_response = make_http_call(args, kwargs, name)

        headers = {}
        status = http_response.code.to_i
        http_response.each_header { |header, value| headers[header.downcase] = value }
        contentType = headers['content-type']
        response = http_response.body

        if contentType === 'application/json' then
          response = response.to_s
          begin
            response = ('{['.include? response[0]) ? JSON.parse(response) : JSON.parse("[#{response}]")[0]
          rescue
            response = nil
          end
        elsif contentType =~ /^text\/.*$/i then
          response = response.to_s
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

    private :__append_version__
    private :__append_path__
    private :__append_lib_path__

  end

  private_constant :LibGen

end
