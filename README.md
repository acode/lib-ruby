# Autocode standard library Ruby bindings

Basic Ruby bindings for Autocode standard library service accession

Used to interface with services built using [Autocode](https://autocode.com) and
the [Autocode CLI](https://github.com/acode/cli).

The `lib` package is available on [RubyGems: lib](https://rubygems.org/gems/lib) and
operates as zero-dependency interface to run StdLib functions. This means that
you can utilize any service on StdLib without installing any additional
dependencies, and when you've deployed services to StdLib, you have a pre-built
Ruby SDK --- for example;

### Inline Style

```ruby
require 'lib'

begin
  result = Lib.yourUsername.hostStatus.exec! name: 'Dolores Abernathy'
rescue Exception => err
  # Handle Error
end
```

### Block Style

```ruby
require 'lib'

Lib.yourUsername.hostStatus.exec! name: 'Dolores Abernathy' do |err, result|
  puts err
  puts result
end
```

To discover StdLib services, visit https://stdlib.com/search. To build a service,
get started with [the StdLib CLI tools](https://github.com/stdlib/lib).

## Installation

To install in an existing Ruby project;

```shell
$ gem install lib
```

## Usage

```ruby
require 'lib'

# [1]: Call "stdlib.reflect" function, the latest version, from StdLib
result = Lib.stdlib.reflect.exec! 0, 1, kwarg: 'value'

# [2]: Call "stdlib.reflect" function from StdLib, with "dev" environment
result = Lib.stdlib.reflect['@dev'].exec! 0, 1, kwarg: 'value'

# [3]: Call "stdlib.reflect" function from StdLib, with "release" environment
#      This is equivalent to (1)
result = Lib.stdlib.reflect['@release'].exec! 0, 1, kwarg: 'value'

# [4]: Call "stdlib.reflect" function from StdLib, with specific version
#      This is equivalent to (1)
result = Lib.stdlib.reflect['@0.0.1'].exec! 0, 1, kwarg: 'value'

# [5]: Call functions within the service (not just the defaultFunction)
#      This is equivalent to (1) when "main" is the default function
result = Lib.stdlib.reflect.main.exec! 0, 1, kwarg: 'value'

# Valid string composition from first object property only:
result = Lib['stdlib.reflect'].exec! 0, 1, kwarg: 'value'
result = Lib['stdlib.reflect[@dev]'].exec! 0, 1, kwarg: 'value'
result = Lib['stdlib.reflect[@release]'].exec! 0, 1, kwarg: 'value'
result = Lib['stdlib.reflect[@0.0.1]'].exec! 0, 1, kwarg: 'value'
result = Lib['stdlib.reflect.main'].exec! 0, 1, kwarg: 'value'
result = Lib['stdlib.reflect[@dev].main'].exec! 0, 1, kwarg: 'value'
result = Lib['stdlib.reflect[@release].main'].exec! 0, 1, kwarg: 'value'
result = Lib['stdlib.reflect[@0.0.1].main'].exec! 0, 1, kwarg: 'value'
```

## Additional Information

To learn more about Autocode and the standard library, visit
[autocode.com](https://autocode.com) or read the
[Autocode CLI documentation on GitHub](https://github.com/acode/cli).

You can follow the development team on Twitter, [@AutocodeHQ](https://twitter.com/AutocodeHQ)

Autocode is &copy; 2016 - 2021 Polybit Inc.
