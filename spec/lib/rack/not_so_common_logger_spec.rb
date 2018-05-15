# frozen_string_literal: true

require 'rack/not_so_common_logger'
require 'rack/lint'
require 'rack/mock'
require 'timecop'

require 'logger'

RSpec.describe Rack::NotSoCommonLogger do
  obj    = 'foobar'
  length = obj.size

  app = Rack::Lint.new lambda { |_env|
    [200, { 'Content-Type' => 'text/html', 'Content-Length' => length.to_s }, [obj]]
  }

  app_without_length = Rack::Lint.new lambda { |_env|
    [200, { 'Content-Type' => 'text/html' }, []]
  }

  app_with_zero_length = Rack::Lint.new lambda { |_env|
    [200, { 'Content-Type' => 'text/html', 'Content-Length' => '0' }, []]
  }

  it 'logs to rack.errors by default' do
    res = Rack::MockRequest.new(described_class.new(app)).get('/')

    expect(res.errors).to_not be_empty
    expect(res.errors).to match(/"GET \/ " 200 #{length} /)
  end

  it 'logs to anything with +write+' do
    log = StringIO.new
    Rack::MockRequest.new(described_class.new(app, log)).get('/')

    expect(log.string).to match(/"GET \/ " 200 #{length} /)
  end

  it 'works with standartd library logger' do
    logdev = StringIO.new
    log = Logger.new(logdev)
    Rack::MockRequest.new(described_class.new(app, log)).get('/')

    expect(logdev.string).to match(/"GET \/ " 200 #{length} /)
  end

  it 'logs - content length if header is missing' do
    res = Rack::MockRequest.new(described_class.new(app_without_length)).get('/')

    expect(res.errors).to_not be_empty
    expect(res.errors).to match(/"GET \/ " 200 - /)
  end

  it 'logs - content length if header is zero' do
    res = Rack::MockRequest.new(described_class.new(app_with_zero_length)).get('/')

    expect(res.errors).to_not be_empty
    expect(res.errors).to match(/"GET \/ " 200 - /)
  end

  it 'logs in almost common log format' do
    log = StringIO.new
    Timecop.freeze(Time.at(0)) do
      Rack::MockRequest.new(described_class.new(app, log)).get('/')
    end

    md = /\[([^\]]+)\] "(\w+) \/ " (\d{3}) \d+ ([\d\.]+)/.match(log.string)

    expect(md).to_not be_nil
    time, method, status, duration = *md.captures
    expect(time).to eq Time.at(0).strftime('%d/%b/%Y:%H:%M:%S %z')
    expect(method).to eq 'GET'
    expect(status).to eq '200'
    expect((0..1)).to include duration.to_f
  end
end
